# Provides an API to fetch parameters from the current request.
module Athena::Framework::Params::ParamFetcherInterface
  # Returns the value of the parameter with the provided *name*.
  #
  # Optionally allows determing if the params should be validated strictly.  See the "Strict" section of `ARTA::QueryParam`.
  abstract def get(name : String, strict : Bool? = nil)

  # Yields the name and value of each `ATH::Params::ParamInterface` related to the current `ATH::Action#params`.
  #
  # Optionally allows determing if the params should be validated strictly.  See the "Strict" section of `ARTA::QueryParam`.
  abstract def each(strict : Bool? = nil, & : String, _ -> Nil) : Nil
end
