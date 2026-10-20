# Stores the attributes of an `AHTTP::Session`.
#
# Each value is stored as JSON, so any type that can be serialized via `#to_json` and deserialized via `.from_json` can be stored.
# E.g. scalars, arrays, hashes, or types that include `JSON::Serializable`.
class Athena::HTTP::Session::AttributeBag
  include Athena::HTTP::Session::BagInterface

  # :inherit:
  property name : String = "attributes"

  # :inherit:
  getter storage_key : String

  @attributes = Hash(String, String).new

  def initialize(@storage_key : String = "_athena_attributes"); end

  # :inherit:
  def load(pull : JSON::PullParser?) : Nil
    @attributes = Hash(String, String).new

    return unless pull

    pull.read_object do |key|
      @attributes[key] = pull.read_raw
    end
  end

  # :inherit:
  def empty? : Bool
    @attributes.empty?
  end

  # :inherit:
  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      @attributes.each do |name, value|
        builder.field(name) { builder.raw value }
      end
    end
  end

  # Returns `true` if an attribute with the provided *name* exists, otherwise `false`.
  def has?(name : String) : Bool
    @attributes.has_key? name
  end

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*.
  #
  # Raises a `KeyError` if no attribute with that name exists.
  def get(name : String, type : T.class) : T forall T
    type.from_json @attributes.fetch(name) { raise KeyError.new "No session attribute exists with the name '#{name}'." }
  end

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*, or `nil` if it does not exist.
  def get?(name : String, type : T.class) : T? forall T
    @attributes[name]?.try { |value| type.from_json value }
  end

  # Sets the attribute with the provided *name* to the provided *value*.
  def set(name : String, value : _) : Nil
    @attributes[name] = value.to_json
  end

  # Returns all attributes, with their values serialized as JSON.
  def all : Hash(String, String)
    @attributes
  end

  # Removes the attribute with the provided *name*, if it exists.
  def remove(name : String) : Nil
    @attributes.delete name
  end

  # :inherit:
  def clear : Nil
    @attributes.clear
  end
end
