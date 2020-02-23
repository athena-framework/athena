# A container for storing key/value pairs.  Can be used to store arbitrary data within the context of a request.
struct Athena::Routing::ParameterBag
  private abstract struct Param; end

  private record Parameter(T) < Param, value : T

  @parameters : Hash(String, Param) = Hash(String, Param).new

  # Returns `true` if a parameter with the provided *name* exists, otherwise `false.
  def has?(name : String) : Bool
    @parameters.has_key? name
  end

  # Returns the value of the parameter with the provided *name* if it exists, otherwise `nil`.
  def get?(name : String)
    @parameters[name]?.try &.value
  end

  # Returns the value *name*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String)
    get?(name) || raise KeyError.new "No parameter exists with the name '#{name}'"
  end

  {% for type in [Bool, Int, Float, String] %}
    # Returns the value for *name* casted to a `{{type}}`.
    def get(name : String, _type : {{type}}.class) : {{type}}
      get(name).as({{type}})
    end
  {% end %}

  # Sets a parameter with the provided *name* to *value*.
  def set(name : String, value : _) : Nil
    @parameters[name] = Parameter.new value
  end

  # Removes the parameter with the provided *name*.
  def remove(name : String) : Nil
    @parameters.delete name
  end
end
