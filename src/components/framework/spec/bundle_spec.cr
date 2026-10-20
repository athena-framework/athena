require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: %(require "./spec_helper.cr")
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: %(require "./spec_helper.cr")
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

  describe AHTTP::Session do
    it "is not wired if not enabled" do
      assert_compiles <<-'CR'
        ATH.configure({
          framework: {
            session: {
              enabled: false,
            },
          },
        })

        macro finished
          macro finished
            \{%
               services = ADI::ServiceContainer::SERVICE_HASH
            %}
            ASPEC.compile_time_assert(\{{ services["athena_http_kernel_listeners_session"].nil? }}, "Expected athena_http_kernel_listeners_session service to not exist")
            ASPEC.compile_time_assert(\{{ services["athena_http_kernel_controller_value_resolvers_session"].nil? }}, "Expected athena_http_kernel_controller_value_resolvers_session service to not exist")
          end
        end
      CR
    end

    it "correctly wires up the services based on its configuration" do
      assert_compiles <<-'CR'
        ATH.configure({
          framework: {
            test:    false,
            session: {
              enabled:                   true,
              handler_id:                nil,
              save_path:                 "/tmp/dir",
              name:                      "SESSION",
              cookie_lifetime:           3600,
              cookie_path:               "/path",
              cookie_domain:             "example.com",
              cookie_secure:             true,
              cookie_httponly:           false,
              cookie_samesite:           :strict,
              gc_maxlifetime:            600,
              gc_probability:            2,
              gc_divisor:                1000,
              metadata_update_threshold: 30,
            },
          },
        })

        macro finished
          macro finished
            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_storage_handler_file"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["save_path"]["value"] == "/tmp/dir" }}, "Expected save_path to be /tmp/dir")
            ASPEC.compile_time_assert(\{{ parameters["max_lifetime"]["value"] == 600 }}, "Expected max_lifetime to be 600")

            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_storage_factory"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["handler"]["value"].stringify == "athena_http_session_storage_handler_file" }}, "Expected handler to be athena_http_session_storage_handler_file")
            ASPEC.compile_time_assert(\{{ parameters["name"]["value"] == "SESSION" }}, "Expected name to be SESSION")
            ASPEC.compile_time_assert(\{{ parameters["gc_max_lifetime"]["value"] == 600 }}, "Expected gc_max_lifetime to be 600")
            ASPEC.compile_time_assert(\{{ parameters["gc_probability"]["value"] == 2 }}, "Expected gc_probability to be 2")
            ASPEC.compile_time_assert(\{{ parameters["gc_divisor"]["value"] == 1000 }}, "Expected gc_divisor to be 1000")
            ASPEC.compile_time_assert(\{{ parameters["cookie_lifetime"]["value"] == 3600 }}, "Expected cookie_lifetime to be 3600")
            ASPEC.compile_time_assert(\{{ parameters["metadata_update_threshold"]["value"] == 30 }}, "Expected metadata_update_threshold to be 30")

            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_factory"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["storage_factory"]["value"].stringify == "athena_http_session_storage_factory" }}, "Expected storage_factory to be athena_http_session_storage_factory")

            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_kernel_listeners_session"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["session_factory"]["value"].stringify == "athena_http_session_factory" }}, "Expected session_factory to be athena_http_session_factory")
            ASPEC.compile_time_assert(\{{ parameters["debug"]["value"] == true }}, "Expected debug to be true")
            ASPEC.compile_time_assert(\{{ parameters["cookie_path"]["value"] == "/path" }}, "Expected cookie_path to be /path")
            ASPEC.compile_time_assert(\{{ parameters["cookie_domain"]["value"] == "example.com" }}, "Expected cookie_domain to be example.com")
            ASPEC.compile_time_assert(\{{ parameters["cookie_secure"]["value"] == true }}, "Expected cookie_secure to be true")
            ASPEC.compile_time_assert(\{{ parameters["cookie_http_only"]["value"] == false }}, "Expected cookie_http_only to be false")
            ASPEC.compile_time_assert(\{{ parameters["cookie_samesite"]["value"].stringify == "::HTTP::Cookie::SameSite.new(:strict)" }}, "Expected cookie_samesite to be strict")

            \{%
               service = ADI::ServiceContainer::SERVICE_HASH["athena_http_kernel_controller_value_resolvers_session"]
            %}
            ASPEC.compile_time_assert(\{{ service["tags"][ATHR::Interface::TAG][0]["priority"] == 50 }}, "Expected the session value resolver to have a priority of 50")
          end
        end
      CR
    end

    it "requires a positive gc_divisor" do
      assert_compile_time_error "'gc_divisor' must be greater than 0.", <<-'CR'
        ATH.configure({
          framework: {
            session: {
              gc_divisor: 0,
            },
          },
        })
      CR
    end

    it "uses the default save path of the file handler" do
      assert_compiles <<-'CR'
        ATH.configure({
          framework: {
            test:    false,
            session: {
              handler_id: nil,
            },
          },
        })

        macro finished
          macro finished
            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_storage_handler_file"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["save_path"]["value"] == parameters["save_path"]["default_value"] }}, "Expected save_path to be its default value")
          end
        end
      CR
    end

    it "uses the configured handler" do
      assert_compiles <<-'CR'
        @[ADI::Register(name: "custom_session_handler")]
        class CustomSessionHandler < AHTTP::Session::Storage::Handler::Memory; end

        ATH.configure({
          framework: {
            test:    false,
            session: {
              handler_id: "custom_session_handler",
            },
          },
        })

        macro finished
          macro finished
            \{%
               parameters = ADI::ServiceContainer::SERVICE_HASH["athena_http_session_storage_factory"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["handler"]["value"].stringify == "custom_session_handler" }}, "Expected handler to be custom_session_handler")
            ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::SERVICE_HASH["athena_http_session_storage_handler_file"].nil? }}, "Expected athena_http_session_storage_handler_file service to not exist")
            ASPEC.compile_time_assert(\{{ !ADI::ServiceContainer::SERVICE_HASH["athena_http_session_factory"]["public"] }}, "Expected athena_http_session_factory to be private")
          end
        end
      CR
    end

    it "requires sessions to be enabled to use the session of the browser" do
      assert_compile_time_error "'ATH::Spec::HTTPBrowser#session' requires sessions to be enabled via 'framework.session.enabled'.", <<-'CR'
        ATH.configure({
          framework: {
            session: {
              enabled: false,
            },
          },
        })

        ATH::Spec::HTTPBrowser.new.session
      CR
    end

    it "requires test mode to use the session of the browser" do
      assert_compile_time_error "'ATH::Spec::HTTPBrowser#session' requires 'framework.test' to be enabled.", <<-'CR'
        ATH.configure({
          framework: {
            test: false,
          },
        })

        ATH::Spec::HTTPBrowser.new.session
      CR
    end

    it "keeps sessions in memory in test mode" do
      assert_compiles <<-'CR'
        ATH.configure({
          framework: {
            test:    true,
            session: {
              handler_id:     "custom_session_handler",
              gc_maxlifetime: 600,
            },
          },
        })

        macro finished
          macro finished
            \{%
               services = ADI::ServiceContainer::SERVICE_HASH
               parameters = services["athena_http_session_storage_factory"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ parameters["handler"]["value"].stringify == "athena_http_session_storage_handler_memory" }}, "Expected handler to be athena_http_session_storage_handler_memory")
            ASPEC.compile_time_assert(\{{ services["athena_http_session_storage_handler_memory"]["parameters"]["max_lifetime"]["value"] == 600 }}, "Expected max_lifetime to be 600")
            ASPEC.compile_time_assert(\{{ services["athena_http_session_storage_handler_file"].nil? }}, "Expected athena_http_session_storage_handler_file service to not exist")
            ASPEC.compile_time_assert(\{{ services["athena_http_session_factory"]["public"] }}, "Expected athena_http_session_factory to be public")
          end
        end
      CR
    end
  end
end
