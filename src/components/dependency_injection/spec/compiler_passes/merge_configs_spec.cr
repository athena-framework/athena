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

            raise "#{config}" unless config["default_locale"] == "en"
            raise "#{config}" unless config["cors"]["defaults"]["allow_credentials"] == true
            raise "#{config}" unless config["cors"]["defaults"]["allow_origin"].size == 1
            raise "#{config}" unless config["cors"]["defaults"]["allow_origin"][0] == "*"
          %}
        end
      end
    CR
  end
end
