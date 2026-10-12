# Integrates the Serializer component with the [dependency injection](/DependencyInjection/) component, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-serializer/bundle` to register the bundle; it does not require any configuration:
#
# ```
# require "athena"
# require "athena-serializer/bundle"
# ```
#
# The bundle registers the `serializer` service, which may be injected via `ASR::SerializerInterface`:
#
# ```
# @[ADI::Register]
# class ArticleExporter
#   def initialize(@serializer : ASR::SerializerInterface); end
#
#   def export(article : Article) : String
#     @serializer.serialize article, :yaml
#   end
# end
# ```
#
# When registered, the framework also uses it to serialize the data returned from controller actions, and to deserialize request bodies into `ASR::Serializable` types.
@[ADI::Bundle("serializer")]
struct Athena::Serializer::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  # :nodoc:
  module Schema
    include ADI::Extension::Schema
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH[object_constructor_id = "serializer_object_constructor"] = {
              class: Athena::Serializer::InstantiateObjectConstructor,
            }

            ALIASES[Athena::Serializer::ObjectConstructorInterface] = [
              {id: object_constructor_id, public: false},
            ]

            SERVICE_HASH[navigator_factory_id = "serializer_navigator_factory"] = {
              class: Athena::Serializer::Navigators::NavigatorFactory,
            }

            ALIASES[Athena::Serializer::Navigators::NavigatorFactoryInterface] = [
              {id: navigator_factory_id, public: false},
            ]

            SERVICE_HASH[serializer_id = "serializer"] = {
              class: Athena::Serializer::Serializer,
            }

            ALIASES[Athena::Serializer::SerializerInterface] = [
              {id: serializer_id, public: false},
            ]
          %}
        {% end %}
      end
    end
  end
end
