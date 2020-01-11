module Athena::Routing::ParamConverterInterface(T)
  abstract def convert(value : String) : T
end
