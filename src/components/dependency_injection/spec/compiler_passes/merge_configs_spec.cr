require "../spec_helper"

describe ADI::ServiceContainer::MergeConfigs do
  it "deep merges consecutive `ADI.configure` call", tags: "compiled" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper"

      module Schema
        include ADI::Extension::Schema

        property default_locale : String

        module Cors
          include ADI::Extension::Schema

          module Defaults
            include ADI::Extension::Schema

            property allow_credentials : Bool = false
            property allow_origin : Array(String) = [] of String
          end
        end
      end

      ADI.register_extension "test", Schema

      ADI.configure({
        test: {
          cors: {
            defaults: {
              allow_credentials: false,
              allow_origin:      ["*"] of String,
            },
          },
        },
      })

      ADI.configure({
        test: {
          cors: {
            defaults: {
              allow_credentials: true,
            },
          },
        },
      })

      ADI.configure({
        test: {
          default_locale: "en",
        },
      })

      macro finished
        macro finished
          \{%
            config = ADI::CONFIG["test"]
          %}
          ASPEC.compile_time_assert(\{{ config["default_locale"] == "en" }}, "Expected default_locale to be en")
          ASPEC.compile_time_assert(\{{ config["cors"]["defaults"]["allow_credentials"] == true }}, "Expected allow_credentials to be true")
          ASPEC.compile_time_assert(\{{ config["cors"]["defaults"]["allow_origin"].size == 1 }}, "Expected allow_origin size to be 1")
          ASPEC.compile_time_assert(\{{ config["cors"]["defaults"]["allow_origin"][0] == "*" }}, "Expected allow_origin[0] to be *")
        end
      end
    CR
  end
end
