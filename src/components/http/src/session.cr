require "json"
require "random/secure"

# Stores data about the client across requests, such as the logged in user or flash messages.
#
# The session is only loaded from its `AHTTP::Session::Storage::Interface` once it is used, and the data of each request using it is persisted once the request is done.
#
# Attributes are stored as JSON, so any type that can be serialized via `#to_json` and deserialized via `.from_json` can be stored.
# E.g. scalars, arrays, hashes, or types that include `JSON::Serializable`.
#
# ```
# session.set "cart", [1, 2, 3]
# session.get "cart", Array(Int32) # => [1, 2, 3]
# session.get? "user_id", Int64    # => nil
#
# session.flash_bag.add "notice", "Your changes were saved!"
# ```
class Athena::HTTP::Session
  # Returns how many times the session was used, e.g. by accessing its bags or checking if it is empty.
  #
  # Used to determine if a request used the session, e.g. to mark its response as private.
  getter usage_index : Int32 = 0

  # :nodoc:
  setter usage_index : Int32

  @attribute_name : String
  @flash_name : String

  # The data of each registered bag, used to check if the session is empty without starting it.
  @bags = [] of AHTTP::Session::BagInterface

  # Creates a new session, stored via the provided *storage*.
  #
  # The optional *usage_reporter* is called each time the session is used, see `#usage_index`.
  def initialize(
    @storage : AHTTP::Session::Storage::Interface,
    attributes : AHTTP::Session::AttributeBag = AHTTP::Session::AttributeBag.new,
    flashes : AHTTP::Session::FlashBag = AHTTP::Session::FlashBag.new,
    @usage_reporter : Proc(Nil)? = nil,
  )
    @attribute_name = attributes.name
    @flash_name = flashes.name

    self.register_bag attributes
    self.register_bag flashes
  end

  # Starts the session, loading its data.
  # Returns `true` once the session is started.
  #
  # The session is automatically started once its data is accessed.
  def start : Bool
    @storage.start
  end

  # Returns `true` if an attribute with the provided *name* exists, otherwise `false`.
  def has?(name : String) : Bool
    self.attribute_bag.has? name
  end

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*.
  #
  # Raises a `KeyError` if no attribute with that name exists.
  def get(name : String, type : T.class) : T forall T
    self.attribute_bag.get name, type
  end

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*, or `nil` if it does not exist.
  def get?(name : String, type : T.class) : T? forall T
    self.attribute_bag.get? name, type
  end

  # Sets the attribute with the provided *name* to the provided *value*.
  def set(name : String, value : _) : Nil
    self.attribute_bag.set name, value
  end

  # Returns all attributes, with their values serialized as JSON.
  def all : Hash(String, String)
    self.attribute_bag.all
  end

  # Removes the attribute with the provided *name*, if it exists.
  def remove(name : String) : Nil
    self.attribute_bag.remove name
  end

  # Removes all attributes.
  def clear : Nil
    self.attribute_bag.clear
  end

  # Returns `true` if the session is started, otherwise `false`.
  def started? : Bool
    @storage.started?
  end

  # Returns `true` if none of the session's bags have data, otherwise `false`.
  def empty? : Bool
    self.report_usage if self.started?

    @bags.all? &.empty?
  end

  # Clears all session data and gives the session a new ID, removing the data of the current ID.
  # Optionally sets the *lifetime* of its cookie in seconds, `0` meaning until the browser is closed.
  #
  # Returns `true` if the session was given a new ID, otherwise `false`.
  def invalidate(lifetime : Int32? = nil) : Bool
    @storage.clear

    self.migrate true, lifetime
  end

  # Gives the session a new ID while keeping its data, optionally removing the data of the current ID if *destroy* is `true`.
  # Optionally sets the *lifetime* of its cookie in seconds, `0` meaning until the browser is closed.
  #
  # Should be used whenever the privileges of the client change, such as when logging in, to prevent [session fixation](https://owasp.org/www-community/attacks/Session_fixation).
  #
  # Returns `true` if the session was given a new ID, otherwise `false`.
  def migrate(destroy : Bool = false, lifetime : Int32? = nil) : Bool
    @storage.regenerate destroy, lifetime
  end

  # Persists the session data and closes the session.
  #
  # The session is automatically saved once the request is done.
  def save : Nil
    @storage.save
  end

  # Returns the ID of the session, or an empty string if it does not have one yet.
  def id : String
    @storage.id
  end

  # Sets the ID of the session to load once it is started.
  def id=(id : String) : Nil
    @storage.id = id unless @storage.id == id
  end

  # Returns the name of the session, i.e. the name of its cookie.
  def name : String
    @storage.name
  end

  # Sets the name of the session.
  def name=(name : String) : Nil
    @storage.name = name
  end

  # Returns the bag storing the session's metadata, such as when it was created.
  def metadata_bag : AHTTP::Session::Storage::MetadataBag
    self.report_usage

    @storage.metadata_bag
  end

  # Registers the provided *bag*, whose data is loaded and persisted along with the session.
  def register_bag(bag : AHTTP::Session::BagInterface) : Nil
    @storage.register_bag bag
    @bags << bag
  end

  # Returns the bag registered with the provided *name*, starting the session if needed.
  def bag(name : String) : AHTTP::Session::BagInterface
    self.report_usage

    @storage.bag name
  end

  # Returns the bag storing the session's flash messages.
  def flash_bag : AHTTP::Session::FlashBag
    self.bag(@flash_name).as AHTTP::Session::FlashBag
  end

  private def attribute_bag : AHTTP::Session::AttributeBag
    self.bag(@attribute_name).as AHTTP::Session::AttributeBag
  end

  private def report_usage : Nil
    @usage_index += 1

    if (usage_reporter = @usage_reporter) && @usage_index >= 0
      usage_reporter.call
    end
  end
end
