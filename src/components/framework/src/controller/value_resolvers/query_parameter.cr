@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 110}])]
struct Athena::Framework::Controller::ValueResolvers::QueryParameter
  include Athena::Framework::Controller::ValueResolvers::Interface

  configuration ::Athena::Framework::Annotations::MapQueryParameter,
    name : String? = nil,
    validation_failed_status : HTTP::Status = :not_found

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    return unless ann = parameter.annotation_configurations[ATHA::MapQueryParameter]?

    name = ann.name || parameter.name
    validation_failed_status = ann.validation_failed_status

    params = request.query_params

    unless params.has_key? name
      return if parameter.nilable? || parameter.has_default?

      raise ATH::Exceptions::HTTPException.from_status validation_failed_status, "Missing query parameter: '#{name}'."
    end

    value = if parameter.instance_of? Array
              params.fetch_all name
            else
              params[name]
            end

    begin
      parameter.type.from_parameter value
    rescue ex : ArgumentError
      # Catch type cast errors and bubble it up as a BadRequest
      raise ATH::Exceptions::HTTPException.from_status validation_failed_status, "Invalid query parameter: '#{name}'.", cause: ex
    end
  end
end
