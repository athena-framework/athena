require "./parameter"

module Athena::Routing::Parameters
  module Param; end

  abstract struct Parameter(T)
    include Param

    # The name of the parameter.
    getter name : String

    # The value to use if it was not provided
    getter default : T?

    # If the value should be processed via a converter.
    getter converter : ART::Converters::ConverterInterface.class | Nil = nil

    def initialize(@name : String, @default : T? = nil, @converter : ART::Converters::ConverterInterface.class | Nil = nil); end

    # Extracts `self` from *request*.
    protected abstract def extract(request : HTTP::Request) : String?

    # Returns the final parameter value from *request*.
    #
    # Handles any processing required by `converter`
    # or returning `default` if a value is missing.
    def parse(request : HTTP::Request) : T
      value = extract request

      {% unless T.nilable? %}
        if value.nil?
          return default.not_nil! if !default.nil?
          raise "Missing required parameter #{@name}"
        end
      {% else %}
        if value.nil?
          return @default unless default.nil?
          return nil
        end
      {% end %}

      # Convert the string type to its expected type.
      Athena::Types.convert_type(value, T)
    end
  end
end
