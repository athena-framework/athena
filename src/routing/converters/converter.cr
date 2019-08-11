module Athena::Routing::Converters
  # Base struct of Param Converters.
  abstract struct Converter(T, P)
    # Converts the input string *value* into `T`.
    abstract def convert(value : String) : T
  end
end
