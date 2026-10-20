# Manages the lifecycle of an `AHTTP::Session`, persisting its data via the provided `AHTTP::Session::Storage::Handler::Interface`.
#
# * The session is only loaded once it is started, and is identified by a random 128 bit ID
# * Unknown or expired session IDs are replaced by a new ID, so a client can't choose its own session ID
# * The session data is only written if it changed, otherwise only the session's timestamp is updated
# * Empty sessions are not persisted, and are removed if they were
# * Expired sessions are removed via the handler's `#gc` method on *gc_probability* / *gc_divisor* of the started sessions
#
# The session data is persisted as a JSON object, with the data of each bag under its storage key.
class Athena::HTTP::Session::Storage
  include Athena::HTTP::Session::Storage::Interface

  # The session IDs that are accepted from the client.
  # Only allows characters that are safe to use in e.g. file names.
  VALID_ID = /\A[a-zA-Z0-9,-]{22,250}\z/

  # :inherit:
  getter id : String = ""

  # :inherit:
  getter name : String

  # :inherit:
  getter metadata_bag : AHTTP::Session::Storage::MetadataBag

  # :inherit:
  getter? started : Bool = false

  @bags = Hash(String, AHTTP::Session::BagInterface).new

  # The data as it was read, so that it is only written again if it changed.
  @read_data : String = ""

  # Creates a new storage, persisting the session via the provided *handler*.
  #
  # The *name* is the name of the session, i.e. its cookie.
  # The *gc_max_lifetime* is how many seconds a session may be unused for before the handler removes it.
  def initialize(
    @handler : AHTTP::Session::Storage::Handler::Interface,
    @metadata_bag : AHTTP::Session::Storage::MetadataBag = AHTTP::Session::Storage::MetadataBag.new,
    @name : String = "athena_session_id",
    @gc_max_lifetime : Int32 = 1440,
    @gc_probability : Int32 = 1,
    @gc_divisor : Int32 = 100,
  )
  end

  # :inherit:
  def start : Bool
    return true if @started

    id = @id
    data = id.matches?(VALID_ID) ? @handler.read(id) : ""
    id, data = self.create_id if data.empty?

    @id = id
    @read_data = data

    self.collect_garbage
    self.load_session data

    true
  end

  # :inherit:
  #
  # Raises an `AHTTP::Exception::Logic` if the session is already started.
  def id=(id : String)
    raise AHTTP::Exception::Logic.new "Cannot change the ID of an active session." if @started

    @id = id
  end

  # :inherit:
  #
  # Raises an `AHTTP::Exception::Logic` if the session is already started.
  def name=(name : String)
    raise AHTTP::Exception::Logic.new "Cannot change the name of an active session." if @started

    @name = name
  end

  # :inherit:
  #
  # Starts the session if needed, so that a session that was not used yet still gets a new ID.
  # If *destroy* is `false`, the current ID keeps the current data, so requests still using it keep working.
  def regenerate(destroy : Bool = false, lifetime : Int32? = nil) : Bool
    self.start

    if destroy
      @handler.destroy @id
    else
      self.write_session @id, self.serialize
    end

    @metadata_bag.stamp_new lifetime
    @id, @read_data = self.create_id

    true
  end

  # :inherit:
  def save : Nil
    return unless @started

    self.write_session @id, self.serialize
    @handler.close

    @started = false
  end

  # :inherit:
  def clear : Nil
    self.start

    @bags.each_value &.clear
    @metadata_bag.load nil
  end

  # :inherit:
  #
  # Raises an `AHTTP::Exception::Logic` if the session is already started.
  def register_bag(bag : AHTTP::Session::BagInterface) : Nil
    raise AHTTP::Exception::Logic.new "Cannot register a bag when the session is already started." if @started

    @bags[bag.name] = bag
  end

  # :inherit:
  #
  # Raises an `AHTTP::Exception::InvalidArgument` if no bag with the provided *name* is registered.
  def bag(name : String) : AHTTP::Session::BagInterface
    bag = @bags[name]? || raise AHTTP::Exception::InvalidArgument.new "The session bag '#{name}' is not registered."

    self.start

    bag
  end

  # Returns a new ID that is not used by an existing session, along with its data, which is always empty.
  # The ID is also read so that the handler knows it is new.
  private def create_id : {String, String}
    loop do
      id = Random::Secure.hex 16
      data = @handler.read id

      return {id, data} if data.empty?
    end
  end

  private def write_session(id : String, data : String) : Nil
    if data.empty?
      @handler.destroy id
    elsif data == @read_data
      @handler.update_timestamp id, data
    else
      @handler.write id, data
    end
  end

  private def collect_garbage : Nil
    return unless @gc_probability > 0 && Random.rand(@gc_divisor) < @gc_probability

    @handler.gc @gc_max_lifetime
  end

  private def load_session(data : String) : Nil
    values = Hash(String, String).new

    unless data.empty?
      pull = JSON::PullParser.new data
      pull.read_object do |key|
        values[key] = pull.read_raw
      end
    end

    self.each_bag do |bag|
      bag.load values[bag.storage_key]?.try { |value| JSON::PullParser.new value }
    end
  rescue JSON::ParseException | OverflowError
    # Data that can't be loaded is treated as an empty session.
    self.each_bag &.load(nil)
  ensure
    @started = true
  end

  # Returns the data to persist, or an empty string if the session is empty, as the metadata alone is not worth persisting.
  private def serialize : String
    return "" if @bags.each_value.all? &.empty?

    JSON.build do |builder|
      builder.object do
        self.each_bag do |bag|
          next if bag.empty?

          builder.field(bag.storage_key) { bag.to_json builder }
        end
      end
    end
  end

  private def each_bag(& : AHTTP::Session::BagInterface ->) : Nil
    @bags.each_value { |bag| yield bag }
    yield @metadata_bag
  end
end
