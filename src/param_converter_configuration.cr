module Athena::Routing
  # Parent type of param converter configuration used for typing.
  #
  # See `ART::ParamConverterConfiguration`.
  abstract struct ParamConverterConfigurationBase
    # Needs to be defined due to https://github.com/crystal-lang/crystal/issues/6996
    # for the case of there being no converters
    def name; end

    # Needs to be defined due to https://github.com/crystal-lang/crystal/issues/6996
    # for the case of there being no converters
    def converter; end
  end

  # Stores metadata about a specific param converter that should be applied to a value.
  struct ParamConverterConfiguration(T) < ParamConverterConfigurationBase
    # The name of the argument `self` should be applied against.
    getter name : String

    @converter_wrapper : Proc(ART::ParamConverterInterface(T))

    # An `ART::ParamConverterInterface` that should be applied on the argument.
    #
    # OPTIMIZE: Make this store an `ART::ParamConverterInterface(T).class` once [this issue](https://github.com/crystal-lang/crystal/issues/8574) is resolved.
    getter converter : ART::ParamConverterInterface(T) { @converter_wrapper.call }

    def initialize(@name : String, @converter_wrapper : Proc(ART::ParamConverterInterface(T))); end
  end
end
