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
    getter converter : ART::Converters::ConverterInterface? = nil

    def initialize(@name : String, @default : T? = nil, @converter : ART::Converters::ConverterInterface? = nil, @type : T.class = T); end

    # Extracts the string value from *request*.
    protected abstract def extract(request : HTTP::Request) : String?

    # Returns the parsed value from *request*.
    def parse(request : HTTP::Request) : T
      value = extract request

      {% unless T.nilable? %}
        if value.nil?
          return default.not_nil! if !default.nil?
          raise "Missing required parameter #{@name}"
        end
      {% else %}
        return @default if value.nil? && !default.nil?
        return nil if value.nil?
      {% end %}

      # Convert the string type to its expected type.
      Athena::Types.convert_type(value, T)
    end
  end
end
