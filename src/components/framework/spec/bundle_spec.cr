require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line - 1 # Account for spec_helper require
    require "./spec_helper.cr"
    #{code}
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line - 1 # Account for spec_helper require
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
              %}
              ASPEC.compile_time_assert(\{{ arg =~ /allow_credentials: true/ }}, "Expected allow_credentials: true")
              ASPEC.compile_time_assert(\{{ arg =~ /allow_origin: \["allow_origin", \/foo\/\]/ }}, "Expected allow_origin")
              ASPEC.compile_time_assert(\{{ arg =~ /allow_headers: \["allow_headers", "x-my-header"]/ }}, "Expected allow_headers")
              ASPEC.compile_time_assert(\{{ arg =~ /allow_methods: \["allow_methods"]/ }}, "Expected allow_methods")
              ASPEC.compile_time_assert(\{{ arg =~ /expose_headers: \["expose_headers", "x-my-header"]/ }}, "Expected expose_headers")
              ASPEC.compile_time_assert(\{{ arg =~ /max_age: 123/ }}, "Expected max_age: 123")
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
            %}
            ASPEC.compile_time_assert(\{{ service["parameters"]["format_negotiator"]["value"].stringify == "athena_framework_view_format_negotiator" }}, "Expected format_negotiator to be athena_framework_view_format_negotiator")

            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_view_format_negotiator"]
               map = service["calls"]
            %}
            ASPEC.compile_time_assert(\{{ map.size == 4 }}, "Expected 4 format negotiator rules")

            # Hostname rule
            \{%
               m0, rule = map[0][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m0.stringify]["parameters"]["matchers"]["value"]
            %}
            ASPEC.compile_time_assert(\{{ matcher.includes? %(AHTTP::RequestMatcher::Hostname.new(/api\\.example\\.com/)) }}, "Expected hostname matcher for api.example.com")
            ASPEC.compile_time_assert(\{{ rule.includes? "ATH::View::FormatNegotiator::Rule.new" }}, "Expected hostname rule to be a FormatNegotiator::Rule")
            ASPEC.compile_time_assert(\{{ rule =~ /fallback_format: "json"/ }}, "Expected hostname rule fallback_format: json")
            ASPEC.compile_time_assert(\{{ rule =~ /prefer_extension: true/ }}, "Expected hostname rule prefer_extension: true")
            ASPEC.compile_time_assert(\{{ rule =~ /priorities: \["json", "xml"\]/ }}, "Expected hostname rule priorities: json, xml")
            ASPEC.compile_time_assert(\{{ rule =~ /stop: false/ }}, "Expected hostname rule stop: false")

            # Path rule
            \{%
               m1, rule = map[1][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m1.stringify]["parameters"]["matchers"]["value"]
            %}
            ASPEC.compile_time_assert(\{{ matcher.includes? %(AHTTP::RequestMatcher::Path.new(/^\\/image/)) }}, "Expected path matcher for /image")
            ASPEC.compile_time_assert(\{{ rule.includes? "ATH::View::FormatNegotiator::Rule.new" }}, "Expected path rule to be a FormatNegotiator::Rule")
            ASPEC.compile_time_assert(\{{ rule =~ /fallback_format: false/ }}, "Expected path rule fallback_format: false")
            ASPEC.compile_time_assert(\{{ rule =~ /prefer_extension: true/ }}, "Expected path rule prefer_extension: true")
            ASPEC.compile_time_assert(\{{ rule =~ /priorities: \["jpeg", "gif"\]/ }}, "Expected path rule priorities: jpeg, gif")
            ASPEC.compile_time_assert(\{{ rule =~ /stop: true/ }}, "Expected path rule stop: true")

            # Methods rule
            \{%
               m2, rule = map[2][1]
               matcher = ADI::ServiceContainer::SERVICE_HASH[m2.stringify]["parameters"]["matchers"]["value"]
            %}
            ASPEC.compile_time_assert(\{{ matcher.includes? %(AHTTP::RequestMatcher::Method.new(["HEAD"])) }}, "Expected method matcher for HEAD")
            ASPEC.compile_time_assert(\{{ rule.includes? "ATH::View::FormatNegotiator::Rule.new" }}, "Expected methods rule to be a FormatNegotiator::Rule")
            ASPEC.compile_time_assert(\{{ rule =~ /fallback_format: "json"/ }}, "Expected methods rule fallback_format: json")
            ASPEC.compile_time_assert(\{{ rule =~ /prefer_extension: false/ }}, "Expected methods rule prefer_extension: false")
            ASPEC.compile_time_assert(\{{ rule =~ /priorities: \["xml", "html"\]/ }}, "Expected methods rule priorities: xml, html")
            ASPEC.compile_time_assert(\{{ rule =~ /stop: false/ }}, "Expected methods rule stop: false")

            # Tests matcher reuse logic
            \{%
               m3, rule = map[3][1]
            %}
            ASPEC.compile_time_assert(\{{ m3 == m1 }}, "Expected matcher reuse for path rules")
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
            %}
            ASPEC.compile_time_assert(\{{ !service.nil? }}, "Expected athena_framework_listeners_file service to exist")

            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_framework_file_parser"]
            %}
            ASPEC.compile_time_assert(\{{ !service.nil? }}, "Expected athena_framework_file_parser service to exist")

            \{%
               parameters = service["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["temp_dir"]["value"] == "/tmp/dir" }}, "Expected temp_dir to be /tmp/dir")
            ASPEC.compile_time_assert(\{{ parameters["max_uploads"]["value"] == 12 }}, "Expected max_uploads to be 12")
            ASPEC.compile_time_assert(\{{ parameters["max_file_size"]["value"] == 1000_i64 }}, "Expected max_file_size to be 1000")
          end
        end
      CR
    end
  end
end
