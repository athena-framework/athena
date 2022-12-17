@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: -100}])]
# Resolves the default value of a controller action parameter if no other value was provided;
# using `nil` if the parameter does not have a default value, but is nilable.
#
# ```
# require "athena"
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/default")]
#   def default(id : Int32 = 123) : Int32
#     id
#   end
#
#   @[ARTA::Get("/nilable")]
#   def nilable(id : Int32?) : Int32?
#     id
#   end
# end
#
# ATH.run
#
# # GET /default # => 123
# # GET /nilable # => null
# ```
struct Athena::Framework::Controller::ValueResolvers::DefaultValue
  include Athena::Framework::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    return if !parameter.has_default? && !parameter.nilable?

    parameter.default_value?
  end
end
