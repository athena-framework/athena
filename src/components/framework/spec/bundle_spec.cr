require "./spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
  CR
end

private def assert_success(code : String, *, codegen : Bool = false, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_success <<-CR, line: line, codegen: codegen
    require "./spec_helper.cr"
    #{code}
  CR
end

describe ATH::Bundle, tags: "compiled" do
  describe ATH::Listeners::CORS do
    it "wildcard allow_headers with allow_credentials" do
      assert_error "'expose_headers' cannot contain a wildcard ('*') when 'allow_credentials' is 'true'.", <<-CODE
          ATH.configure({
            framework: {
              cors: {
                enabled:  true,
                defaults: {
                  allow_credentials: true,
                  expose_headers:    ["*"],
                },
              },
            },
          })
        CODE
    end

    it "does not exist if not enabled" do
      assert_error "undefined method 'athena_framework_listeners_cors'", <<-CODE
          ADI.container.athena_framework_listeners_cors
        CODE
    end

    # TODO: Is there a better way to test bundle extension logic?
    it "correctly wires up the listener based on its configuration" do
      assert_success <<-CODE, codegen: true
          ATH.configure({
            framework: {
              cors: {
                enabled:  true,
                defaults: {
                  allow_credentials: true,
                  allow_origin: ["allow_origin", /foo/],
                  allow_headers: ["allow_headers"],
                  allow_methods: ["allow_methods"],
                  expose_headers: ["expose_headers"],
                  max_age: 123
                },
              },
            },
          })

          it do
            config = ADI.container.athena_framework_listeners_cors.@config
            config.allow_credentials?.should be_true
            config.allow_origin.should eq ["allow_origin", /foo/]
            config.allow_headers.should eq ["allow_headers"]
            config.allow_methods.should eq ["allow_methods"]
            config.expose_headers.should eq ["expose_headers"]
            config.max_age.should eq 123
          end
        CODE
    end
  end
end
