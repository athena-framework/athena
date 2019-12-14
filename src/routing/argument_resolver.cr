@[ADI::Register]
struct Athena::Routing::ArgumentResolver
  include ADI::Service

  def resolve(ctx : HTTP::Server::Context) : Array
    route = ctx.request.route

    route.parameters.map do |param|
      next ctx.request if param.is_a? ART::Parameters::RequestParameter

      value = param.extract ctx.request

      if param.required?
        if value.nil?
          next param.default.not_nil! if !param.default.nil?
          raise ART::Exceptions::BadRequest.new "Missing required #{param.parameter_type} parameter '#{param.name}'"
        end
      else
        if value.nil?
          next param.default unless param.default.nil?
          next nil
        end
      end

      # Check if there is a param converter that should modify the value
      if converter = route.converters.find { |cc| cc.name == param.name }.try &.converter
        next converter.convert value
      end

      begin
        # Otherwise convert the string type to its expected type.
        Athena::Types.convert_type(value, param.type)
      rescue ex : ArgumentError
        # Catch type cast errors and bubble it up as an UnprocessableEntity
        raise ART::Exceptions::UnprocessableEntity.new "Required parameter '#{param.name}' with value '#{value}' could not be converted into a valid '#{param.type}'", cause: ex
      end
    end
  end
end
