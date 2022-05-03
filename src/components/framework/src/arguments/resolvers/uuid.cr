require "uuid"

@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
# Handles resolving a [UUID](https://crystal-lang.org/api/UUID.html) from a string value that is stored in the request's `ATH::Request#attributes`.
#
# ```
# require "athena"
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/uuid/{uuid}")]
#   def get_uuid(uuid : UUID) : String
#     "Version: #{uuid.version} - Variant: #{uuid.variant}"
#   end
# end
#
# ATH.run
#
# # GET /uuid/b115c7a5-0a13-47b4-b4ac-55b3e2686946 # => "Version: V4 - Variant: RFC4122"
# ```
#
# TIP: Checkout `ART::Requirement` for an easy way to restrict/validate the version of the UUID that is allowed.
#
# TODO: Update this to use `UUID.parse?` in Crystal 1.5.0.
struct Athena::Framework::Arguments::Resolvers::UUID
  include Athena::Framework::Arguments::Resolvers::Interface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    argument.instance_of?(::UUID) && request.attributes.has?(argument.name, String)
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    ::UUID.new value = request.attributes.get argument.name, String
  rescue ex : ArgumentError
    # Catch invalid UUID errors and bubble it up as a BadRequest
    raise ATH::Exceptions::BadRequest.new "Parameter '#{argument.name}' with value '#{value}' is not a valid 'UUID'.", cause: ex
  end
end
