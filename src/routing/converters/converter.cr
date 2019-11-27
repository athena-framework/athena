module Athena::Routing::Converters
  module ConverterInterface; end

  # Base struct of Param Converters.
  abstract struct Converter(T, P)
    include ConverterInterface

    # Converts the input string *value* into `T`.
    abstract def convert(value : String) : T
  end
end
