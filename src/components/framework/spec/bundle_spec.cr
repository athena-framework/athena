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
      assert_error "'expose_headers' cannot contain a wildcard ('*') when 'allow_credentials' is 'true'.", <<-'CODE'
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

    it "correctly wires up the listener based on its configuration" do
      assert_success <<-'CODE', codegen: true
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

  describe ATH::Listeners::Format do
    it "correctly wires up the listener based on its configuration" do
      assert_success <<-'CODE', codegen: true
        ATH.configure({
          framework: {
            format_listener: {
              enabled: true,
              rules:   [
                {priorities: ["json", "xml"], host: /api\.example\.com/, fallback_format: "json"},
                {path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false, stop: true},
                {methods: ["HEAD"], priorities: ["xml", "html"], prefer_extension: false},
                {path: /^\/image/, priorities: ["foo"]},
              ],
            },
          },
        })

        it do
          negotiator = ADI.container.athena_framework_listeners_format.as(ATH::Listeners::Format).@format_negotiator.as(ATH::View::FormatNegotiator)
          map = negotiator.@map
          map.size.should eq 4

          # Hostname rule
          matcher, rule = map[0]
          rule.should eq ATH::View::FormatNegotiator::Rule.new(fallback_format: "json", prefer_extension: true, priorities: ["json", "xml"], stop: false)
          m0 = matcher.should be_a ATH::RequestMatcher
          m0.@matchers.should eq [ATH::RequestMatcher::Hostname.new(/api\.example\.com/)]

          # Path rule
          matcher, rule = map[1]
          rule.should eq ATH::View::FormatNegotiator::Rule.new(fallback_format: false, prefer_extension: true, priorities: ["jpeg", "gif"], stop: true)
          m1 = matcher.should be_a ATH::RequestMatcher
          m1.@matchers.should eq [ATH::RequestMatcher::Path.new(/^\/image/)]

          # Methods rule
          matcher, rule = map[2]
          rule.should eq ATH::View::FormatNegotiator::Rule.new(fallback_format: "json", prefer_extension: false, priorities: ["xml", "html"], stop: false)
          m2 = matcher.should be_a ATH::RequestMatcher
          m2.@matchers.should eq [ATH::RequestMatcher::Method.new("HEAD")]

          # Tests matcher reuse logic
          matcher, _ = map[3]
          m3 = matcher.should be_a ATH::RequestMatcher
          m3.should be m1
        end
      CODE
    end
  end
end
