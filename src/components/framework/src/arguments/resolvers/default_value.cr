@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: -100}])]
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
struct Athena::Framework::Arguments::Resolvers::DefaultValue
  include Athena::Framework::Arguments::Resolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    return if !argument.has_default? && !argument.nilable?

    argument.default_value?
  end
end
