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
                  allow_headers: ["allow_headers", "X-My-Header"],
                  allow_methods: ["allow_methods"],
                  expose_headers: ["expose_headers", "X-My-Header"],
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

                 unless arg =~ /allow_credentials: true/
                   raise "#{arg}"
                 end

                 unless arg =~ /allow_origin: \["allow_origin", \/foo\/\]/
                   raise "#{arg}"
                 end

                 unless arg =~ /allow_headers: \["allow_headers", "x-my-header"]/
                   raise "#{arg}"
                 end

                 unless arg =~ /allow_methods: \["allow_methods"]/
                   raise "#{arg}"
                 end

                 unless arg =~ /expose_headers: \["expose_headers", "x-my-header"]/
                   raise "#{arg}"
                 end

                 unless arg =~ /max_age: 123/
                   raise "#{arg}"
                 end
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
               unless service["parameters"]["format_negotiator"]["value"].stringify == "athena_framework_view_format_negotiator"
                 raise ""
               end
            %}

            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_view_format_negotiator"]
               map = service["calls"]

               unless map.size == 4
                 raise "#{map}"
               end

               # Hostname rule
               m0, rule = map[0][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m0.stringify]["parameters"]["matchers"]["value"]
               unless matcher.includes? %(AHTTP::RequestMatcher::Hostname.new(/api\\.example\\.com/))
                 raise "#{matcher}"
               end

               unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
                 raise "#{rule}"
               end

               unless rule =~ /fallback_format: "json"/
                 raise "#{rule}"
               end

               unless rule =~ /prefer_extension: true/
                 raise "#{rule}"
               end

               unless rule =~ /priorities: \["json", "xml"\]/
                 raise "#{rule}"
               end

               unless rule =~ /stop: false/
                 raise "#{rule}"
               end

               # Path rule
               m1, rule = map[1][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m1.stringify]["parameters"]["matchers"]["value"]
               unless matcher.includes? %(AHTTP::RequestMatcher::Path.new(/^\\/image/))
                 raise "#{matcher}"
               end

               unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
                 raise "#{rule}"
               end

               unless rule =~ /fallback_format: false/
                 raise "#{rule}"
               end

               unless rule =~ /prefer_extension: true/
                 raise "#{rule}"
               end

               unless rule =~ /priorities: \["jpeg", "gif"\]/
                 raise "#{rule}"
               end

               unless rule =~ /stop: true/
                 raise "#{rule}"
               end

               # Methods rule
               m2, rule = map[2][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m2.stringify]["parameters"]["matchers"]["value"]
               unless matcher.includes? %(AHTTP::RequestMatcher::Method.new(["HEAD"]))
                 raise "#{matcher}"
               end

               unless rule.includes? "ATH::View::FormatNegotiator::Rule.new"
                 raise "#{rule}"
               end

               unless rule =~ /fallback_format: "json"/
                 raise "#{rule}"
               end

               unless rule =~ /prefer_extension: false/
                 raise "#{rule}"
               end

               unless rule =~ /priorities: \["xml", "html"\]/
                 raise "#{rule}"
               end

               unless rule =~ /stop: false/
                 raise "#{rule}"
               end

               # Tests matcher reuse logic
               m3, rule = map[3][1]
               unless m3 == m1
                 raise "#{m3} == #{m1}"
               end
            %}
          end
        end
      CR
    end
  end

  describe ATH::Listeners::File do
    it "correctly wires up the services based on its configuration" do
      assert_compiles <<-'CR'
        ATH.configure({
          framework: {
            file_uploads: {
              enabled: true,
              temp_dir: "/tmp/dir",
              max_uploads: 12,
              max_file_size: 1_000_i64,
            },
          },
        })

        macro finished
          macro finished
            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_listeners_file"]
               unless service
                 raise ""
               end

               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_file_parser"]
               unless service
                 raise ""
               end

               parameters = service["parameters"]

               unless parameters["temp_dir"]["value"] == "/tmp/dir"
                 raise "#{parameters["temp_dir"]}"
               end

               unless parameters["max_uploads"]["value"] == 12
                 raise "#{parameters["max_uploads"]}"
               end

               unless parameters["max_file_size"]["value"] == 1000_i64
                 raise "#{parameters["max_file_size"]}"
               end
            %}
          end
        end
      CR
    end
  end
end
