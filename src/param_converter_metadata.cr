abstract struct Athena::Routing::ParamConverterMetadata
  # The name of the argument the converte should be applied to.
  getter name : String

  getter converter : ART::ParamConverterInterface.class

  def initialize(@name : String, @converter : ART::ParamConverterInterface.class); end
end

struct Athena::Routing::DefaultParamConverterMetadata < Athena::Routing::ParamConverterMetadata
end
