# Stores flash messages, messages that are only meant to be shown to the user once, grouped by *type*.
# E.g. `"notice"` or `"error"`.
#
# Reading messages via `#get` or `#all` removes them, while `#peek` and `#peek_all` leave them in place.
class Athena::HTTP::Session::FlashBag
  include Athena::HTTP::Session::BagInterface

  # :inherit:
  property name : String = "flashes"

  # :inherit:
  getter storage_key : String

  @flashes = Hash(String, Array(String)).new

  def initialize(@storage_key : String = "_athena_flashes"); end

  # :inherit:
  def load(pull : JSON::PullParser?) : Nil
    @flashes = Hash(String, Array(String)).new

    return unless pull

    pull.read_object do |type|
      @flashes[type] = Array(String).new pull
    end
  end

  # :inherit:
  def empty? : Bool
    @flashes.empty?
  end

  # :inherit:
  def to_json(builder : JSON::Builder) : Nil
    @flashes.to_json builder
  end

  # Adds the provided *message* to those of the provided *type*.
  def add(type : String, message : String) : Nil
    (@flashes[type] ||= [] of String) << message
  end

  # Returns the messages of the provided *type*, or the provided *default* if there are none, without removing them.
  def peek(type : String, default : Array(String) = [] of String) : Array(String)
    self.has?(type) ? @flashes[type] : default
  end

  # Returns the messages of all types, without removing them.
  def peek_all : Hash(String, Array(String))
    @flashes
  end

  # Returns and removes the messages of the provided *type*, or returns the provided *default* if there are none.
  def get(type : String, default : Array(String) = [] of String) : Array(String)
    return default unless self.has? type

    @flashes.delete(type) || default
  end

  # Returns and removes the messages of all types.
  def all : Hash(String, Array(String))
    flashes = @flashes
    @flashes = Hash(String, Array(String)).new
    flashes
  end

  # Replaces the messages of the provided *type* with the provided *messages*.
  def set(type : String, messages : String | Array(String)) : Nil
    @flashes[type] = messages.is_a?(String) ? [messages] : messages
  end

  # Replaces the messages of all types with the provided *messages*.
  def set_all(messages : Hash(String, Array(String))) : Nil
    @flashes = messages
  end

  # Returns `true` if there are messages of the provided *type*, otherwise `false`.
  def has?(type : String) : Bool
    @flashes[type]?.try { |messages| !messages.empty? } || false
  end

  # Returns the types that have messages.
  def keys : Array(String)
    @flashes.keys
  end

  # :inherit:
  def clear : Nil
    self.all
  end
end
