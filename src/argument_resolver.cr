@[ADI::Register]
# :nodoc:
#
# A service that encapsulates the logic for resolving action arguments from a request.
struct Athena::Routing::ArgumentResolver
  include ADI::Service

  # Returns an array of parameters for the `ART::Route` associated with the given *ctx*.
  def resolve(ctx : HTTP::Server::Context) : Array
    route = ctx.request.route

    # Iterate over each `ART::Parameters::Parameter` defined on the route
    route.parameters.map do |param|
      # Handle request/response parameters
      next ctx.request if param.is_a? ART::Parameters::RequestParameter
      next ctx.response if param.is_a? ART::Parameters::ResponseParameter

      value = param.extract ctx.request

      if param.required?
        if value.nil?
          # Return the default value if defined if the param was not supplied
          next param.default.not_nil! if !param.default.nil?

          # Otherwise raise a BadRequest exception
          raise ART::Exceptions::BadRequest.new "Missing required #{param.parameter_type} parameter '#{param.name}'"
        end
      else
        if value.nil?
          # Return the default value if defined if the param was not supplied
          next param.default unless param.default.nil?

          # Otherwise return `nil`
          next nil
        end
      end

      # Check if there is a param converter that should modify the value
      if converter = route.converters.find { |cc| cc.name == param.name }.try &.converter
        next converter.convert value
      end

      begin
        # Otherwise convert the string type to its expected type.
        param.type.not_nil!.from_parameter value
      rescue ex : ArgumentError
        next nil unless param.required?

        # Catch type cast errors and bubble it up as an UnprocessableEntity
        raise ART::Exceptions::UnprocessableEntity.new "Required parameter '#{param.name}' with value '#{value}' could not be converted into a valid '#{param.type}'", cause: ex
      end
    end
  end
end
