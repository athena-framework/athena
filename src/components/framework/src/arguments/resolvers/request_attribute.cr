@[ADI::Register(name: "argument_resolver_request_attribute", tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 100}])]
# Handles resolving a value that is stored in the request's `ATH::Request#attributes`.
# This includes any path/query parameters, custom types values stored via an `AED::EventListenerInterface`, or extra `defaults` stored within the routing annotation.
#
# ```
# @[ARTA::Get("/{id}")]
# def get_id(id : Int32) : Int32
#   id
# end
# ```
struct Athena::Framework::Arguments::Resolvers::RequestAttribute
  include Athena::Framework::Arguments::Resolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    return unless request.attributes.has? argument.name

    value = request.attributes.get argument.name

    argument.type.from_parameter value
  rescue ex : ArgumentError
    # Catch type cast errors and bubble it up as a BadRequest
    raise ATH::Exceptions::BadRequest.new "Parameter '#{argument.name}' with value '#{value}' could not be converted into a valid '#{argument.type}'.", cause: ex
  end
end
