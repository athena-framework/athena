# Provides an API to fetch parameters from the current request.
module Athena::Routing::Params::ParamFetcherInterface
  # Returns the value of the parameter with the provided *name*.
  #
  # Optionally allows determing if the params should be validated strictly.  See [ART::QueryParam@strict](../QueryParam.html#strict).
  abstract def get(name : String, strict : Bool? = nil)

  # Yields the name and value of each `ART::Params::ParamInterface` related to the current `ART::Action#params`.
  #
  # Optionally allows determing if the params should be validated strictly.  See [ART::QueryParam@strict](../QueryParam.html#strict).
  abstract def each(strict : Bool? = nil, & : String, _ -> Nil) : Nil
end
