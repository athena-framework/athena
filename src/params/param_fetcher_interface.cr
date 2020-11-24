module Athena::Routing::Params::ParamFetcherInterface
  abstract def get(name : String, strict : Bool? = nil)
  abstract def each(strict : Bool? = nil, & : String, _ -> Nil) : Nil
end
