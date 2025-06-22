require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
  CR
end

describe ATH::Bundle, tags: "compiled" do
  describe ATH::Listeners::CORS do
    it "wildcard allow_headers with allow_credentials" do
      assert_compile_time_error "'expose_headers' cannot contain a wildcard ('*') when 'allow_credentials' is 'true'.", <<-'CR'
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
        CR
    end

    it "does not exist if not enabled" do
      assert_compile_time_error "undefined method 'athena_framework_listeners_cors'", <<-CR
          ADI.container.athena_framework_listeners_cors
        CR
    end

    it "correctly wires up the listener based on its configuration" do
      assert_compiles <<-'CR'
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

          macro finished
            macro finished
              \{%
                 service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_listeners_cors"]
                 arg = service["parameters"]["config"]["value"]

                 raise "#{arg}" unless arg =~ /allow_credentials: true/
                 raise "#{arg}" unless arg =~ /allow_origin: \["allow_origin", \/foo\/\]/
                 raise "#{arg}" unless arg =~ /allow_headers: \["allow_headers"]/
                 raise "#{arg}" unless arg =~ /allow_methods: \["allow_methods"]/
                 raise "#{arg}" unless arg =~ /expose_headers: \["expose_headers"]/
                 raise "#{arg}" unless arg =~ /max_age: 123/
              %}
            end
          end
        CR
    end
  end

  describe ATH::Listeners::Format do
    it "correctly wires up the listener based on its configuration" do
      assert_compiles <<-'CR'
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

        macro finished
          macro finished
            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_listeners_format"]
               raise "" unless service["parameters"]["format_negotiator"]["value"].stringify == "athena_framework_view_format_negotiator"
            %}

            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_view_format_negotiator"]
               map = service["calls"]

               raise "#{map}" unless map.size == 4

               # Hostname rule
               m0, rule = map[0][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m0.stringify]["parameters"]["matchers"]["value"]
               raise "#{matcher}" unless matcher.includes? %(ATH::RequestMatcher::Hostname.new(/api\\.example\\.com/))

               raise "#{rule}" unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
               raise "#{rule}" unless rule =~ /fallback_format: "json"/
               raise "#{rule}" unless rule =~ /prefer_extension: true/
               raise "#{rule}" unless rule =~ /priorities: \["json", "xml"\]/
               raise "#{rule}" unless rule =~ /stop: false/

               # Path rule
               m1, rule = map[1][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m1.stringify]["parameters"]["matchers"]["value"]
               raise "#{matcher}" unless matcher.includes? %(ATH::RequestMatcher::Path.new(/^\\/image/))

               raise "#{rule}" unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
               raise "#{rule}" unless rule =~ /fallback_format: false/
               raise "#{rule}" unless rule =~ /prefer_extension: true/
               raise "#{rule}" unless rule =~ /priorities: \["jpeg", "gif"\]/
               raise "#{rule}" unless rule =~ /stop: true/

               # Methods rule
               m2, rule = map[2][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m2.stringify]["parameters"]["matchers"]["value"]
               raise "#{matcher}" unless matcher.includes? %(ATH::RequestMatcher::Method.new(["HEAD"]))

               raise "#{rule}" unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
               raise "#{rule}" unless rule =~ /fallback_format: "json"/
               raise "#{rule}" unless rule =~ /prefer_extension: false/
               raise "#{rule}" unless rule =~ /priorities: \["xml", "html"\]/
               raise "#{rule}" unless rule =~ /stop: false/

               # Tests matcher reuse logic
               m3, rule = map[3][1]
               raise "#{m3} == #{m1}" unless m3 == m1
            %}
          end
        end
      CR
    end
  end
end
