# Included into a `ART::Parameters::Parameter` to indicate that it supports conversion via a `ART::ParamConverterInterface`.
module Athena::Routing::Parameters::Convertable(T)
  # The converter that should be applied to `self`.
  getter converter : ART::ParamConverterInterface(T)? = nil
end
