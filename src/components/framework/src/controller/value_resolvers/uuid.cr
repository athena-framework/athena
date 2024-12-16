require "uuid"

@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 105}])]
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
# TIP: Checkout [ART::Requirement](/Routing/Requirement/) for an easy way to restrict/validate the version of the UUID that is allowed.
struct Athena::Framework::Controller::ValueResolvers::UUID
  include Athena::Framework::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata) : ::UUID?
    return unless parameter.instance_of? ::UUID # TODO: Test making this not nil
    return unless value = request.attributes.get? parameter.name, String

    ::UUID.parse?(value) || raise ATH::Exception::BadRequest.new "Parameter '#{parameter.name}' with value '#{value}' is not a valid 'UUID'."
  end
end
