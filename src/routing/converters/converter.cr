module Athena::Routing::Converters
  abstract struct ParamConverterConfiguration
    # Needs to be defined due to https://github.com/crystal-lang/crystal/issues/6996
    # for the case of there being no converters
    def name; end

    # Needs to be defined due to https://github.com/crystal-lang/crystal/issues/6996
    # for the case of there being no converters
    def converter; end
  end

  # Stores metadata about a specific param converter that should be applied to a value.
  struct ParamConverter(T) < ParamConverterConfiguration
    # The name of the argument `self` should be applied against.
    getter name : String

    @converter_wrapper : Proc(ART::Converters::Converter(T))

    # An `ART::Converters::Converter` that should be applied on the argument.
    #
    # OPTIMIZE: Make this store an `ART::Converters::Converter(T).class` once [this issue](https://github.com/crystal-lang/crystal/issues/8574) is resolved.
    getter converter : ART::Converters::Converter(T) { @converter_wrapper.call }

    def initialize(@name : String, @converter_wrapper : Proc(ART::Converters::Converter(T))); end
  end

  # Base struct of Param Converters.
  abstract struct Converter(T)
    abstract def convert(value : String)
  end
end
