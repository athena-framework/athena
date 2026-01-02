# A container representing parameters defined via `ART::Route#defaults`, or returned when matching a route.
# Allows the value to be of any type.
class Athena::Routing::Parameters
  private abstract struct Param
    abstract def value
    abstract def type_name : String

    def inspect(io : IO) : Nil
      if self.value.is_a?(String | Bool | Number::Primitive)
        return self.value.inspect io
      end

      io << "#<Param(" << self.type_name << ")>"
    end
  end

  private record Parameter(T) < Param, value : T do
    def type_name : String
      {{ T.stringify }}
    end
  end

  @parameters : Hash(String, Param) = Hash(String, Param).new

  def initialize
  end

  def self.new(parameters : self) : self
    parameters
  end

  def self.new(hash : Hash(String, _))
    params = new
    hash.each do |key, value|
      params[key] = value
    end
    params
  end

  # Returns `true` if a parameter with the provided *name* exists, otherwise `false`.
  def has_key?(name : String) : Bool
    @parameters.has_key? name
  end

  # Returns the value of the parameter with the provided *name* as a `String`.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def [](name : String) : String
    @parameters.fetch(name) { raise KeyError.new "No parameter exists with the name '#{name}'." }.value.as(String)
  end

  # Returns the value of the parameter with the provided *name* as a `String` if it exists, otherwise `nil`.
  def []?(name : String) : String?
    @parameters[name]?.try &.value.as?(String)
  end

  # Returns the value of the parameter with the provided *name* casted to the provided *type* if it exists, otherwise `nil`.
  def get?(name : String, type : T.class) : T? forall T
    @parameters[name]?.try &.value.as?(T)
  end

  # Returns the value of the parameter with the provided *name*, casted to the provided *type*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String, type : T.class) : T forall T
    @parameters.fetch(name) { raise KeyError.new "No parameter exists with the name '#{name}'." }.value.as(T)
  end

  # Sets a parameter with the provided *name* to *value*.
  def []=(name : String, value : T) : Nil forall T
    @parameters[name] = Parameter(T).new value
  end

  # Removes the parameter with the provided *name*.
  def delete(name : String) : Nil
    @parameters.delete name
  end

  # :nodoc:
  def raw?(name : String)
    @parameters[name]?.try &.value
  end

  # :nodoc:
  def keys : Array(String)
    @parameters.keys
  end

  # Returns `true` if empty.
  def empty? : Bool
    @parameters.empty?
  end

  # :nodoc:
  def size : Int32
    @parameters.size
  end

  # :nodoc:
  def each(&) : Nil
    @parameters.each do |key, param|
      yield key, param.value
    end
  end

  # :nodoc:
  def dup : self
    copy = self.class.new
    @parameters.each do |key, param|
      copy.@parameters[key] = param
    end
    copy
  end

  # :nodoc:
  def clone : self
    self.dup
  end

  def merge!(other : ART::Parameters) : self
    other.@parameters.each do |key, param|
      @parameters[key] = param
    end
    self
  end

  # :nodoc:
  def merge!(other : ART::Parameters?) : self
    if other
      other.@parameters.each do |key, param|
        @parameters[key] = param
      end
    end
    self
  end

  # Returns a `Hash(String, String?)` representation of these parameters.
  # Values that are not `String?` are converted via `#to_s`.
  def to_h : Hash(String, String?)
    @parameters.to_h do |(key, param)|
      value = param.value
      {key, value.nil? ? nil : value.to_s}
    end
  end

  # :nodoc:
  def ==(other : self) : Bool
    return false unless @parameters.size == other.@parameters.size
    @parameters.each do |key, param|
      return false unless other.@parameters[key]?.try { |p| p.value == param.value }
    end
    true
  end

  # :nodoc:
  def ==(other : Hash(String, String?)) : Bool
    self.to_h == other
  end
end
