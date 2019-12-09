module Athena::Routing::Converters
  abstract struct ParamConverterConfiguration; end

  struct ParamConverter(T) < ParamConverterConfiguration
    # The name of the argument `self` should be applied against.
    getter name : String

    # The type that the argument should be converted into.
    getter type : T.class = T

    # The `ART::Converters::Converter.class` that should be applied on the argument.
    getter converter : ART::Converters::Converter.class

    def initialize(@name : String, @converter : ART::Converters::Converter.class); end
  end

  # Base struct of Param Converters.
  abstract struct Converter
    abstract def convert(value : String)
  end
end
