private abstract struct Athena::Routing::Param; end

private record Athena::Routing::Parameter(T) < Athena::Routing::Param, value : T

struct Athena::Routing::RequestParameters
  include Enumerable({String, Athena::Routing::Param})
  include Iterable({String, Athena::Routing::Param})

  delegate each, to: @params

  @params : Hash(String, ART::Param) = Hash(String, ART::Param).new

  def has?(key : String) : Bool
    @params.has_key? key
  end

  def get?(key : String)
    @params[key]?.try &.value
  end

  def get(key : String)
    get?(key) || raise KeyError.new "No parameter exists with the key '#{key}'"
  end

  def set(key : String, value : _) : Nil
    @params[key] = Athena::Routing::Parameter.new value
  end
end

class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! route : ART::Action

  # See `RequestParameters`.
  property params : ART::RequestParameters = ART::RequestParameters.new

  # Allows storing simple values within the context of a request.
  property attributes = Hash(String, Bool | Int32 | String | Float64 | Nil).new
end
