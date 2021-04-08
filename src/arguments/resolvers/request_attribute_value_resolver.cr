@[ADI::Register(name: "argument_resolver_request_attribute", tags: [{name: ART::Arguments::Resolvers::TAG, priority: 100}])]
# Handles resolving a value that is stored in the request's `ART::Request#attributes`.
# This includes any path/query parameters, or custom types values stored via an `AED::EventListenerInterface`.
#
# ```
# @[ARTA::Get("/:id")]
# def get_id(id : Int32) : Int32
#   id
# end
# ```
struct Athena::Routing::Arguments::Resolvers::RequestAttribute
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ART::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
    request.attributes.has? argument.name
  end

  # :inherit:
  def resolve(request : ART::Request, argument : ART::Arguments::ArgumentMetadata)
    value = request.attributes.get argument.name

    argument.type.from_parameter value
  rescue ex : ArgumentError
    # Catch type cast errors and bubble it up as an BadRequest
    raise ART::Exceptions::BadRequest.new "Required parameter '#{argument.name}' with value '#{value}' could not be converted into a valid '#{argument.type}'", cause: ex
  end
end
