# :nodoc:
module Athena::Routing::ArgumentResolverInterface
  abstract def resolve(request : HTTP::Request, route : ART::Action) : Array
end

@[ADI::Register]
# :nodoc:
#
# A service that encapsulates the logic for resolving action arguments from a request.
struct Athena::Routing::ArgumentResolver
  include Athena::Routing::ArgumentResolverInterface

  # Returns an array of parameters for the `ART::Route` associated with the given *request*.
  def resolve(request : HTTP::Request, route : ART::Action) : Array
    # Iterate over each `ART::Parameters::Parameter` defined on the route
    route.parameters.map do |param|
      # Handle request/response parameters
      next request if param.is_a? ART::Parameters::Request

      # Check if the param supports conversion and has a converter
      if param.is_a?(ART::Parameters::Convertable) && (converter = param.converter)
        # Use the converted value
        next converter.convert request
      end

      value = param.extract request

      if param.required? && value.nil?
        # Use the default if it is not nil
        next param.default unless param.default.nil?

        # Otherwise raise a BadRequest exception
        raise ART::Exceptions::BadRequest.new "Missing required #{param.parameter_type} parameter '#{param.name}'"
      else
        # Use the default if the value is nil
        next param.default if value.nil?
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
