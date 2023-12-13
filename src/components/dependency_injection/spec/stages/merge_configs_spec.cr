require "../spec_helper"

describe ADI::ServiceContainer::MergeConfigs do
  it "deep merges consecutive `ADI.configure` call", tags: "compiler" do
    ASPEC::Methods.assert_success <<-CR
      require "../spec_helper"

      @[ADI::RegisterExtension("test")]
      module FrameworkExtension
        include ADI::Extension

        property default_locale : String

        module Cors
          include ADI::Extension

          module Defaults
            include ADI::Extension

            property? allow_credentials : Bool = false
            property allow_origin : Array(String) = [] of String
          end
        end
      end

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
          it { \\{{ADI::CONFIG["test"]["default_locale"]}}.should eq "en" }
          it { \\{{ADI::CONFIG["test"]["cors"]["defaults"]["allow_credentials"]}}.should be_true }
          it { \\{{ADI::CONFIG["test"]["cors"]["defaults"]["allow_credentials"]}}.should eq ["*"] }
        end
      end
    CR
  end
end
