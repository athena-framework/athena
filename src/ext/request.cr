struct Athena::Routing::ParameterBag
  private abstract struct Param; end

  private record Parameter(T) < Param, value : T

  include Enumerable({String, Param})
  include Iterable({String, Param})

  @parameters : Hash(String, Param) = Hash(String, Param).new

  delegate each, to: @parameters

  # Returns `true` if a parameter with the provided *name* exists, otherwise `false.
  def has?(name : String) : Bool
    @parameters.has_key? name
  end

  # Returns the value of the parameter with the provided *name* if it exists, otherwise `nil`.
  def get?(name : String)
    @parameters[name]?.try &.value
  end

  # Returns the value of the parameter with the provided *name*.
  #
  # Raises a `KeyError` if no parameter with that name exists.
  def get(name : String)
    get?(name) || raise KeyError.new "No parameter exists with the name '#{name}'"
  end

  {% for type in [Bool, Int, Float, String] %}
    # Returns the value for *name* casted to a {{type}}.
    def get(name : String, _type : {{type}}.class) : {{type}}
      get(name).as({{type}})
    end
  {% end %}

  # Sets a parameter with the provided *name* to *value.
  def set(name : String, value : _) : Nil
    @parameters[name] = Parameter.new value
  end

  # Removes the parameter with the provided *name*.
  def remove(name : String) : Nil
    @parameters.delete name
  end
end

class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! route : ART::Action

  # See `ART::ParameterBag`.
  property attributes : ART::ParameterBag = ART::ParameterBag.new
end
