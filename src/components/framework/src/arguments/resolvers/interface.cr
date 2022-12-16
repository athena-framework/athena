# Argument resolvers handle resolving the argument(s) to pass to a controller action based on values stored within the `ATH::Request`, or some other source.
#
# Custom resolvers can be defined by creating a service that implements this interface, and is tagged with `ATH::Arguments::Resolvers::TAG`,
# optionally with a priority to determine the order in which the resolvers are executed.
#
# The tag also accepts an optional *priority* field the determines the order in which the resolvers execute.
# The list of built in resolvers and their priorities can be found on the `ATH::Arguments::Resolvers` module.
#
# WARNING: Resolvers that mutate a value already within the `ATH::Request#attributes`, such as one from a route or query parameter _MUST_ have a priority `>100`
# to ensure the custom logic is applied before the raw value is resolved via the `ATHR::RequestAttribute` resolver.
#
# The first resolver to return a value wins and no other resolvers will be executed for that particular argument.
# The resolver should return `nil` to denote no value could be resolved,
# such as if the argument is of the wrong type, does not have a specific annotation applied, or anything else that can be deduced from either argument.
# If no resolver is able to resole a value for a specific argument, an error is thrown and processing of the request ceases.
#
# For example:
#
# ```
# @[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 10}])]
# struct CustomResolver
#   include ATHR::Interface
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : MyCustomType?
#     # Return early if a value is unresolvable from the current *request* and/or *argument*.
#     return if argument.type != MyCustomType
#
#     # Return the resolved value. It could either come from the request itself, an injected service, or hard coded.
#     MyCustomType.new "foo"
#   end
# end
# ```
#
# Now, given the following controller:
#
# ```
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/")]
#   def root(my_obj : MyCustomType) : String
#     my_obj.name
#   end
# end
#
# # GET / # => "foo"
# ```
#
# Since none of the built-in resolvers are applicable for this parameter type,
# nor is there a *my_obj* value in `ATH::Request#attributes`, assuming no customer listeners manually add it, the `CustomResolver` would take over and provide the value for that parameter.
#
# ## Configuration
#
# In some cases, the request and argument themselves may not be enough to know if a resolver should try to resolve a value or not.
# A naive example would be say you want to have a resolver that multiplies certain `Int32` parameters by `10`.
# It wouldn't be enough to just check if the argument is an `Int32` as that leaves too much room for unexpected contexts to be resolved unexpectedly.
# For such cases a `.configuration` annotation type may be defined to allow marking the specific parameters the related resolver should apply to.
#
# For example:
#
# ```
# # The priority _MUST_ be `>100` to ensure the value isnt preemptively resolved by the `ATHR::RequestAttribute` resolver.
# @[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 110}])]
# struct Multiply
#   include ATHR::Interface
#
#   configuration This
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Int32?
#     # Return early if the controller action parameter doesn't have the annotation.
#     return unless argument.annotation_configurations.has? This
#
#     # Return early if the parameter type is not `Int32`.
#     return if argument.type != Int32
#
#     request.attributes.get(argument.name, Int32) * 10
#   end
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/{num}")]
#   def multiply(
#     @[Multiply::This]
#     num : Int32
#   ) : Int32
#     num
#   end
# end
#
# ATH.run
#
# # GET /10 # => 100
# ```
#
# While this example is quite naive, this pattern is used as part of the `ATHR::RequestBody` to know if an object should be deserialized from the request body, or is intended be supplied some other way.
#
# ### Extra Data
#
# Another use case for this pattern is providing extra data on a per parameter basis.
# For example, say we wanted to allow customizing the multiplier instead of having it hard coded to `10`.
#
# In order to do this we can pass properties to the `.configuration` macro to define what we want to be configurable via the annotation.
# Next we can then use this value in our resolver, and when applying to a specific parameter:
#
# ```
# # The priority _MUST_ be `>100` to ensure the value isnt preemptively resolved by the `ATHR::RequestAttribute` resolver.
# @[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 110}])]
# struct Multiply
#   include ATHR::Interface
#
#   configuration This, multiplier : Int32 = 10
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Int32?
#     # Return early if the controller action parameter doesn't have the annotation.
#     return unless (config = argument.annotation_configurations[This]?)
#
#     # Return early if the parameter type is not `Int32`.
#     return if argument.type != Int32
#
#     request.attributes.get(argument.name, Int32) * config.multiplier
#   end
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/{num}")]
#   def multiply(
#     @[Multiply::This(multiplier: 50)]
#     num : Int32
#   ) : Int32
#     num
#   end
# end
#
# ATH.run
#
# # GET /10 # => 500
# ```
#
# A more real-world example of this pattern is the `ATHR::Time` resolver which allows customizing the format and/or location that should be used to parse the datetime string.
#
# ## Handling Multiple Types
#
# When using an annotation to enable a particular resolver, it may be required to handle parameters of varying types.
# E.g. it should do one thing when enabled on an `Int32` parameter, while a different thing when applied to a `String` parameter.
# But both things are related enough to not warrant dedicated resolvers.
# Because the type of the parameter is stored within a generic type, it can be used to overload the `#resolve` method based on its type
# For example:
#
# ```
# # The priority _MUST_ be `>100` to ensure the value isnt preemptively resolved by the `ATHR::RequestAttribute` resolver.
# @[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 110}])]
# struct MyResolver
#   include ATHR::Interface
#
#   configuration Enable
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(Int32)) : Int32?
#     return unless argument.annotation_configurations.has? Enable
#
#     request.attributes.get(argument.name, Int32) * 10
#   end
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(String)) : String?
#     return unless argument.annotation_configurations.has? Enable
#
#     request.attributes.get(argument.name, String).upcase
#   end
#
#   # :inherit:
#   #
#   # Fallback overload for types other than `Int32` and `String.
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Nil
#   end
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/integer/{value}")]
#   def integer(
#     @[MyResolver::Enable]
#     value : Int32
#   ) : Int32
#     value
#   end
#
#   @[ARTA::Get("/string/{value}")]
#   def string(
#     @[MyResolver::Enable]
#     value : String
#   ) : String
#     value
#   end
# end
#
# ATH.run
#
# # GET /integer/10  # => 100
# # GET /string/foo # => "FOO"
# ```
#
# ### Free Vars
#
# If more precision is required, a [free variable](https://crystal-lang.org/reference/syntax_and_semantics/type_restrictions.html#free-variables)
# can be used to extract the type of the related parameter such that it can be used to generate the proper code.
#
# An example of this is how `ATHR::RequestBody` handles both `ASR::Serializable` and `JSON::Serializable` types via:
#
# ```
# {% begin %}
#   {% if T.instance <= ASR::Serializable %}
#     object = @serializer.deserialize T, body, :json
#   {% elsif T.instance <= JSON::Serializable %}
#     object = T.from_json body
#   {% else %}
#     return
#   {% end %}
# {% end %}
# ```
#
# This works well to make the compiler happy when previous methods are not enough.
#
# ### Strict Typing
#
# In all of the examples so far, the resolvers could be applied to any parameter of any type and all of the logic to resolve a value would happen at runtime.
# In some cases a specific resolver may only support a single, or small subset of types.
# Such as how the `ATHR::RequestBody` resolver only allows `ASR::Serializable` or `JSON::Serializable` types.
# In this case, the `ATHR::Interface::Typed` module may be used to define the allowed parameter types.
#
# WARNING: Strict typing is _ONLY_ supported when a configuration annotation is used to enable the resolver.
#
# ```
# @[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG}])]
# struct MyResolver
#   # Multiple types may also be supplied by providing it a comma separated list.
#   # If `nil` is a valid option, the `Nil` type should also be included.
#   include ATHR::Interface::Typed(String)
#
#   configuration Enable
#
#   # :inherit:
#   def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : String?
#     return unless argument.annotation_configurations.has? Enable
#
#     "foo"
#   end
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/integer")]
#   def integer(
#     @[MyResolver::Enable]
#     value : Int32
#   ) : Int32
#     value
#   end
#
#   @[ARTA::Get("/string")]
#   def string(
#     @[MyResolver::Enable]
#     value : String
#   ) : String
#     value
#   end
# end
#
# ATH.run
#
# # Error: The annotation '@[MyResolver::Enable]' cannot be applied to 'ExampleController#integer:value : Int32'
# # since the 'MyResolver' resolver only supports parameters of type 'String'.
# ```
#
# Since `MyResolver` was defined to only support `String` types, a compile time error is raised when its annotation is applied to a non `String` parameter.
# This feature pairs nicely with the [free var][Athena::Framework::Arguments::Resolvers::Interface--free-vars] section as it essentially allows
# scoping the possible types of `T` to the set of types defined as part of the module.
module Athena::Framework::Arguments::Resolvers::Interface
  # Helper macro around `ACF.configuration_annotation` that allows defining resolver specific annotations.
  # See the underlying macro and the [configuration][Athena::Framework::Arguments::Resolvers::Interface--configuration] section for more information.
  macro configuration(name, *args)
    ACF.configuration_annotation ::{{@type}}::{{name.id}}{% unless args.empty? %}, {{args.splat}}{% end %}
  end

  # Represents an `ATHR::Interface` that only supports a subset of types.
  #
  # See the [strict typing][Athena::Framework::Arguments::Resolvers::Interface--strict-typing] section for more information.
  module Typed(*SupportedTypes)
    include Athena::Framework::Arguments::Resolvers::Interface
  end

  # Returns a value resolved from the provided *request* and *argument* if possible, otherwise returns `nil` if no argument could be resolved.
  abstract def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
end
