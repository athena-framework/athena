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

    def initialize(@name : String, @default : T? = nil, @converter : ART::Converters::ConverterInterface? = nil); end

    # Extracts `self` from *request*.
    protected abstract def extract(request : HTTP::Request) : String?

    # Represents `self`'s type name to use within error handling.
    protected abstract def type : String

    # Returns the final parameter value from *request*.
    #
    # Handles any processing required by `converter`
    # or returning `default` if a value is missing.
    def parse(request : HTTP::Request)
      value = extract request

      {% unless T.nilable? %}
        if value.nil?
          return default.not_nil! if !default.nil?
          raise ART::Exceptions::BadRequest.new "Missing required #{self.type} parameter '#{@name}'"
        end
      {% else %}
        if value.nil?
          return @default unless default.nil?
          return nil
        end
      {% end %}

      if converter = @converter
        return converter.convert value
      end

      # Convert the string type to its expected type.
      Athena::Types.convert_type(value, T)
    rescue ex : ArgumentError
      message = ex.message || "'#{value}' is not a valid #{T}"

      # Catch type cast errors and bubble it up as a BadRequest
      raise ART::Exceptions::BadRequest.new message, cause: ex
    end
  end
end
