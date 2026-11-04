require "./spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "athena-spec"
    require "../../src/bundle"

    @[ADI::Register]
    class TokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
      def supports?(request : AHTTP::Request) : Bool?
        true
      end

      def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
        ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("user")
      end

      def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
        nil
      end

      def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
        nil
      end
    end

    @[ADI::Register]
    class EntryPointAuthenticator < TokenAuthenticator
      include ASEC::EntryPoint::Interface

      def start(request : AHTTP::Request, exception : ASEC::Exception::Authentication? = nil) : AHTTP::Response
        AHTTP::Response.new status: :unauthorized
      end
    end

    @[ADI::Register]
    class OtherEntryPointAuthenticator < EntryPointAuthenticator; end
  CR
end

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: <<-'CR'
    require "athena-spec"
    require "../../src/bundle"

    @[ADI::Register]
    class TokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
      def supports?(request : AHTTP::Request) : Bool?
        true
      end

      def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
        ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("user")
      end

      def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
        nil
      end

      def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
        nil
      end
    end

    @[ADI::Register]
    class EntryPointAuthenticator < TokenAuthenticator
      include ASEC::EntryPoint::Interface

      def start(request : AHTTP::Request, exception : ASEC::Exception::Authentication? = nil) : AHTTP::Response
        AHTTP::Response.new status: :unauthorized
      end
    end

    @[ADI::Register]
    class OtherEntryPointAuthenticator < EntryPointAuthenticator; end

    @[ADI::Register]
    class NotAnAuthenticator; end
  CR
end

describe ASEC::Bundle, tags: "compiled" do
  describe "firewalls" do
    it "registers the services of a firewall" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            providers: {
              users: {memory: {users: {"user" => {password: nil, roles: ["ROLE_USER"]}}}},
            },
            firewalls: {
              main:  {pattern: /^\/api/, custom_authenticators: ["token_authenticator"]},
              admin: {host: /admin\.example\.com/, methods: ["GET", "POST"]},
            },
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              admin_matcher = sh["athena_security_request_matcher_1"]["parameters"]["matchers"]["value"].stringify

              user_provider_listener = sh["athena_security_listener_main_user_provider"]
              global_listeners = sh["event_dispatcher"]["calls"].map { |(_, args)| args[0].stringify }
              firewall_listeners = sh["athena_security_event_dispatcher_main"]["calls"].map { |(_, args)| args[0].stringify }
              manager_params = sh["athena_security_authenticator_manager_main"]["parameters"]
              exception_listener_params = sh["athena_security_exception_listener_main"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ sh["athena_security_firewall_map"]["class"].resolve == Athena::Security::Bundle::FirewallMap }}, "Expected the firewall map to be registered")
            ASPEC.compile_time_assert(\{{ sh["athena_security_user_provider_users"]["class"].resolve == Athena::Security::User::Provider::InMemory }}, "Expected the memory provider to be registered")
            ASPEC.compile_time_assert(\{{ user_provider_listener["parameters"]["user_provider"]["value"].stringify == "athena_security_user_provider_users" }}, "Expected the only provider to be the provider of the firewall")
            ASPEC.compile_time_assert(\{{ global_listeners.includes? "athena_security_firewall" }}, "Expected the firewall to listen to the global event dispatcher")
            ASPEC.compile_time_assert(\{{ !global_listeners.includes? "athena_security_listener_main_user_provider" }}, "Expected the user provider listener to not listen to the global event dispatcher")
            ASPEC.compile_time_assert(\{{ !global_listeners.includes? "athena_security_listener_main_user_checker" }}, "Expected the user checker listener to not listen to the global event dispatcher")
            ASPEC.compile_time_assert(\{{ firewall_listeners.includes? "athena_security_listener_main_user_provider" }}, "Expected the user provider listener to listen to the firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ firewall_listeners.includes? "athena_security_listener_main_user_checker" }}, "Expected the user checker listener to listen to the firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ firewall_listeners.includes? "athena_security_listener_check_authenticator_credentials" }}, "Expected the global credentials listener to listen to the firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ firewall_listeners.includes? "athena_security_listener_password_migrating" }}, "Expected the global password migrating listener to listen to the firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ !firewall_listeners.includes? "athena_security_firewall" }}, "Expected the firewall to not listen to the firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ manager_params["authenticators"]["value"].map(&.stringify) == ["token_authenticator"] }}, "Expected the custom authenticators to be the authenticators of the firewall")
            ASPEC.compile_time_assert(\{{ manager_params["firewall_name"]["value"] == "main" }}, "Expected the name of the firewall")
            ASPEC.compile_time_assert(\{{ exception_listener_params["authentication_entry_point"]["value"] == nil }}, "Expected the firewall to have no entry point")
            ASPEC.compile_time_assert(\{{ sh["athena_security_authenticator_manager_admin"]["parameters"]["authenticators"]["value"].stringify == "[] of Athena::Security::Authenticator::Interface" }}, "Expected a firewall without authenticators")
            ASPEC.compile_time_assert(\{{ admin_matcher.includes?("Hostname.new(/admin\\.example\\.com/)") && admin_matcher.includes?(%(Method.new(["GET", "POST"]))) && !admin_matcher.includes?("Path.new") }}, "Expected the request matcher to match the host and methods")
          end
        end
      CR
    end

    it "registers a firewall with security disabled" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls: {
              assets: {pattern: /^\/assets/, security: false},
              main:   {security: true},
            },
          },
        })

        macro finished
          macro finished
            \{% sh = ADI::ServiceContainer::SERVICE_HASH %}
            ASPEC.compile_time_assert(\{{ sh["athena_security_firewall_context_assets"]["parameters"]["exception_listener"]["value"] == nil }}, "Expected the firewall to have no exception listener")
            ASPEC.compile_time_assert(\{{ sh["athena_security_event_dispatcher_assets"] == nil }}, "Expected the firewall to have no event dispatcher")
            ASPEC.compile_time_assert(\{{ sh["athena_security_authenticator_manager_assets"] == nil }}, "Expected the firewall to have no authenticator manager")
          end
        end
      CR
    end

    it "makes the only authenticator that is an entry point the entry point of its firewall" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls: {
              main: {custom_authenticators: ["token_authenticator", "entry_point_authenticator"]},
            },
          },
        })

        macro finished
          macro finished
            \{% value = ADI::ServiceContainer::SERVICE_HASH["athena_security_exception_listener_main"]["parameters"]["authentication_entry_point"]["value"] %}
            ASPEC.compile_time_assert(\{{ value.stringify == "entry_point_authenticator" }}, "Expected the authenticator that is an entry point to be the entry point")
          end
        end
      CR
    end

    it "uses the configured entry point" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls: {
              main: {
                custom_authenticators: ["entry_point_authenticator", "other_entry_point_authenticator"],
                entry_point:           "other_entry_point_authenticator",
              },
              other: {security: true},
            },
          },
        })

        macro finished
          macro finished
            \{% value = ADI::ServiceContainer::SERVICE_HASH["athena_security_exception_listener_main"]["parameters"]["authentication_entry_point"]["value"] %}
            ASPEC.compile_time_assert(\{{ value.stringify == "other_entry_point_authenticator" }}, "Expected the configured entry point to be the entry point")
          end
        end
      CR
    end

    it "uses the configured provider and user checker" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class CustomUserChecker
          include ASEC::User::Checker::Interface

          def check_pre_auth(user : ASEC::User::Interface) : Nil; end

          def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil; end
        end

        ADI.configure({
          security: {
            providers: {
              first:  {memory: {users: {"first" => {password: nil}}}},
              second: {memory: {users: {"second" => {password: nil}}}},
            },
            firewalls: {
              main: {provider: "second", user_checker: "custom_user_checker", custom_authenticators: ["token_authenticator"]},
            },
          },
        })

        macro finished
          macro finished
            \{% sh = ADI::ServiceContainer::SERVICE_HASH %}
            ASPEC.compile_time_assert(\{{ sh["athena_security_listener_main_user_provider"]["parameters"]["user_provider"]["value"].stringify == "athena_security_user_provider_second" }}, "Expected the configured provider")
            ASPEC.compile_time_assert(\{{ sh["athena_security_listener_main_user_checker"]["parameters"]["user_checker"]["value"].stringify == "custom_user_checker" }}, "Expected the configured user checker")
          end
        end
      CR
    end

    it "copies the global listeners of security events onto each firewall event dispatcher" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class LoginListener
          @[AEDA::AsEventListener]
          def on_login_success(event : ASEC::Events::LoginSuccess) : Nil; end
        end

        @[ADI::Register]
        class RequestListener
          @[AEDA::AsEventListener]
          def on_request(event : AHK::Events::Request) : Nil; end
        end

        ADI.configure({
          security: {
            firewalls: {
              api:  {pattern: /^\/api/},
              main: {security: true},
            },
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              api_listeners = sh["athena_security_event_dispatcher_api"]["calls"].map { |(_, args)| args[0].stringify }
              main_listeners = sh["athena_security_event_dispatcher_main"]["calls"].map { |(_, args)| args[0].stringify }
            %}
            ASPEC.compile_time_assert(\{{ api_listeners.includes?("login_listener") && main_listeners.includes?("login_listener") }}, "Expected the security event listener to listen to each firewall event dispatcher")
            ASPEC.compile_time_assert(\{{ !api_listeners.includes?("request_listener") && !main_listeners.includes?("request_listener") }}, "Expected other listeners to not listen to the firewall event dispatchers")
          end
        end
      CR
    end

    it "shares request matchers between firewalls and access control rules" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls: {
              api:  {pattern: /^\/api/, methods: ["GET"], host: /example\.com/},
              main: {security: true},
            },
            access_control: [
              {path: /^\/api/, methods: ["GET"], host: /example\.com/, role: "ROLE_API"},
              {path: /^\/admin/, role: "ROLE_ADMIN"},
              {role: "ROLE_USER"},
            ],
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              access_map_calls = sh["athena_security_access_map"]["calls"]
              shared_matcher = sh["athena_security_request_matcher_0"]["parameters"]["matchers"]["value"]
            %}
            ASPEC.compile_time_assert(\{{ access_map_calls.map { |(_, args)| args[0].stringify } == ["athena_security_request_matcher_0", "athena_security_request_matcher_1", "athena_security_request_matcher_2"] }}, "Expected a request matcher per distinct rule")
            ASPEC.compile_time_assert(\{{ access_map_calls.map { |(_, args)| args[1] } == ["ROLE_API", "ROLE_ADMIN", "ROLE_USER"] }}, "Expected the role of each rule")
            ASPEC.compile_time_assert(\{{ sh["athena_security_request_matcher_3"] == nil }}, "Expected the firewall to reuse the request matcher of the matching rule")
            ASPEC.compile_time_assert(\{{ shared_matcher.stringify.includes?("Path.new(/^\\/api/)") && shared_matcher.stringify.includes?("Hostname.new(/example\\.com/)") && shared_matcher.stringify.includes?(%(Method.new(["GET"]))) }}, "Expected the request matcher to match the path, host, and methods")
          end
        end
      CR
    end

    it "uses request matcher services" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class APIRequestMatcher
          include AHTTP::RequestMatcher::Interface

          def matches?(request : AHTTP::Request) : Bool
            true
          end
        end

        ADI.configure({
          security: {
            firewalls:      {api: {request_matcher: "api_request_matcher"}},
            access_control: [{request_matcher: "api_request_matcher", role: "ROLE_API"}],
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              firewall_map = sh["athena_security_firewall_map"]["parameters"]
              request_matchers = firewall_map["map"]["value"].stringify
              contexts = firewall_map["contexts"]["value"].stringify
            %}
            ASPEC.compile_time_assert(\{{ sh["athena_security_access_map"]["calls"].map { |(_, args)| args[0].stringify } == ["api_request_matcher"] }}, "Expected the request matcher of the rule")
            ASPEC.compile_time_assert(\{{ request_matchers == %({"api" => api_request_matcher} of String => AHTTP::RequestMatcher::Interface?) }}, "Expected the request matcher of the firewall")
            ASPEC.compile_time_assert(\{{ contexts.includes? %("api" => ->{ athena_security_firewall_context_api.as(Athena::Security::Bundle::FirewallContext) }) }}, "Expected the service locator to provide the context of the firewall")
          end
        end
      CR
    end

    it "errors without firewalls" do
      assert_compile_time_error "The 'security.firewalls' option must define at least one firewall.", <<-'CR'
        ADI.configure({
          security: {
            providers: {users: {memory: {users: {"user" => {password: nil}}}}},
          },
        })
      CR
    end

    it "errors if a custom authenticator is not a service" do
      assert_compile_time_error "Invalid firewall 'main': the custom authenticator 'missing_authenticator' is not a registered service.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {custom_authenticators: ["missing_authenticator"]}},
          },
        })
      CR
    end

    it "errors if a custom authenticator is not an authenticator" do
      assert_compile_time_error "Invalid firewall 'main': the custom authenticator 'not_an_authenticator' (NotAnAuthenticator) must include 'ASEC::Authenticator::Interface'.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {custom_authenticators: ["not_an_authenticator"]}},
          },
        })
      CR
    end

    it "errors if multiple authenticators are entry points" do
      assert_compile_time_error "Because you have multiple authenticators in firewall 'main', you need to set the 'entry_point' key to one of your authenticators ('entry_point_authenticator', 'other_entry_point_authenticator') or a service ID implementing 'ASEC::EntryPoint::Interface'.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {custom_authenticators: ["entry_point_authenticator", "other_entry_point_authenticator"]}},
          },
        })
      CR
    end

    it "errors if the entry point is not a service" do
      assert_compile_time_error "Invalid firewall 'main': the entry point 'missing_entry_point' is not a registered service.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {entry_point: "missing_entry_point"}},
          },
        })
      CR
    end

    it "errors if the entry point is not an entry point" do
      assert_compile_time_error "Invalid firewall 'main': the entry point 'token_authenticator' (TokenAuthenticator) must include 'ASEC::EntryPoint::Interface'.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {entry_point: "token_authenticator"}},
          },
        })
      CR
    end

    it "errors if the provider of a firewall is not configured" do
      assert_compile_time_error "Invalid firewall 'main': user provider 'missing' not found.", <<-'CR'
        ADI.configure({
          security: {
            firewalls: {main: {provider: "missing"}},
          },
        })
      CR
    end

    it "errors if the provider of a firewall with authenticators is ambiguous" do
      assert_compile_time_error "Not configuring explicitly the provider for the 'custom_authenticators' authenticator on 'main' firewall is ambiguous as there is more than one registered provider.", <<-'CR'
        ADI.configure({
          security: {
            providers: {
              first:  {memory: {users: {"first" => {password: nil}}}},
              second: {memory: {users: {"second" => {password: nil}}}},
            },
            firewalls: {main: {custom_authenticators: ["token_authenticator"]}},
          },
        })
      CR
    end

    it "errors if an access control rule has a request matcher alongside other options" do
      assert_compile_time_error "The 'request_matcher' option of an 'access_control' rule cannot be specified alongside other request matching options.", <<-'CR'
        ADI.configure({
          security: {
            firewalls:      {main: {security: true}},
            access_control: [
              {request_matcher: "some_matcher", role: "ROLE_USER"},
              {request_matcher: "some_matcher", path: /^\/admin/, role: "ROLE_ADMIN"},
            ],
          },
        })
      CR
    end
  end

  describe "providers" do
    it "registers the providers" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class AppUserProvider
          include ASEC::User::Provider::Interface

          def load_user_by_identifier(identifier : String) : ASEC::User::Interface
            raise ASEC::Exception::UserNotFound.new
          end

          def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
            user
          end

          def supports_class?(klass : ASEC::User::Interface.class) : Bool
            true
          end
        end

        ADI.configure({
          security: {
            providers: {
              in_memory: {memory: {users: {"admin" => {password: "hash", roles: ["ROLE_ADMIN"]}, "user" => {password: nil}, "guest" => {password: nil, roles: [] of String}}}},
              app:       {id: "app_user_provider"},
              all:       {chain: {providers: ["in_memory", "app"]}},
              none:      {chain: {providers: [] of String}},
            },
            firewalls: {main: {provider: "all", custom_authenticators: ["token_authenticator"]}},
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              users = sh["athena_security_user_provider_in_memory"]["parameters"]["users"]["value"].stringify
              chained = sh["athena_security_user_provider_all"]["parameters"]["providers"]["value"].map(&.stringify)
            %}
            ASPEC.compile_time_assert(\{{ sh["athena_security_user_provider_all"]["class"].resolve == Athena::Security::User::Provider::Chain }}, "Expected a chain provider")
            ASPEC.compile_time_assert(\{{ chained == ["athena_security_user_provider_in_memory", "app_user_provider"] }}, "Expected the chained providers")
            ASPEC.compile_time_assert(\{{ users.includes? %(Athena::Security::User::InMemory.new("admin", "hash", ["ROLE_ADMIN"])) }}, "Expected the admin user")
            ASPEC.compile_time_assert(\{{ users.includes? %(Athena::Security::User::InMemory.new("user", nil, [] of String)) }}, "Expected a user without roles")
            ASPEC.compile_time_assert(\{{ users.includes? %(Athena::Security::User::InMemory.new("guest", nil, [] of String)) }}, "Expected a user with no roles")
          end
        end
      CR
    end

    it "errors if a provider has no type" do
      assert_compile_time_error "You must set a provider definition for the 'users' provider.", <<-'CR'
        ADI.configure({
          security: {
            providers: {users: {memory: {users: nil}}},
            firewalls: {main: {security: true}},
          },
        })
      CR
    end

    it "errors if a provider has multiple types" do
      assert_compile_time_error "You cannot set multiple provider types for the 'users' provider.", <<-'CR'
        ADI.configure({
          security: {
            providers: {users: {id: "app_user_provider", memory: {users: {"user" => {password: nil}}}}},
            firewalls: {main: {security: true}},
          },
        })
      CR
    end

    it "errors if a chain provider chains an unknown provider" do
      assert_compile_time_error "The 'all' provider chains the 'missing' provider, which is not configured.", <<-'CR'
        ADI.configure({
          security: {
            providers: {all: {chain: {providers: ["missing"]}}},
            firewalls: {main: {security: true}},
          },
        })
      CR
    end
  end

  describe "password hashers" do
    it "registers the password hashers" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class LegacyPasswordHasher
          include APH::Interface

          def hash(plain_password : String) : String
            plain_password
          end

          def verify(hashed_password : String, plain_password : String) : Bool
            hashed_password == plain_password
          end

          def needs_rehash?(hashed_password : String) : Bool
            false
          end
        end

        ADI.configure({
          security: {
            password_hashers: {
              ASEC::User::InMemory => :auto,
              "strong"             => {algorithm: :bcrypt, cost: 15},
              "legacy"             => {id: "legacy_password_hasher"},
              "migrated"           => {cost: 12, migrate_from: ["legacy", "strong", "native"]},
            },
            firewalls: {main: {security: true}},
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              factory = sh["athena_security_password_hasher_factory"]
              hashers = factory["parameters"]["password_hashers"]["value"].stringify
            %}
            ASPEC.compile_time_assert(\{{ hashers.includes? %("Athena::Security::User::InMemory" => APH::Native.new,) }}, "Expected types to be keyed by their fully qualified name")
            ASPEC.compile_time_assert(\{{ hashers.includes? %("strong" => APH::Native.new(cost: 15),) }}, "Expected the configured cost")
            ASPEC.compile_time_assert(\{{ hashers.includes? %("legacy" => legacy_password_hasher,) }}, "Expected the configured service")
            ASPEC.compile_time_assert(\{{ hashers.includes? %("migrated" => APH::Migrating.new(APH::Native.new(cost: 12), legacy_password_hasher, APH::Native.new(cost: 15), APH::Native.new)) }}, "Expected the migrating hasher")
            ASPEC.compile_time_assert(\{{ factory["referenced_services"].includes? "legacy_password_hasher" }}, "Expected the hasher service to be referenced")
            ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[Athena::PasswordHasher::UserPasswordHasherInterface][0]["id"] == "athena_security_user_password_hasher" }}, "Expected the user password hasher alias")
            ASPEC.compile_time_assert(\{{ sh["athena_security_command_user_password_hash"] == nil }}, "Expected no command without the console bundle")
          end
        end
      CR
    end

    it "registers the hash password command with the console bundle" do
      assert_compiles <<-'CR'
        require "athena-console"
        require "athena-console/bundle"

        ADI.configure({
          security: {
            password_hashers: {
              ASEC::User::InMemory => :auto,
              "strong"             => {cost: 15},
            },
            firewalls: {main: {security: true}},
          },
        })

        macro finished
          macro finished
            \{% command = ADI::ServiceContainer::SERVICE_HASH["athena_security_command_user_password_hash"] %}
            ASPEC.compile_time_assert(\{{ command["class"].resolve == Athena::PasswordHasher::Commands::UserPasswordHash }}, "Expected the command to be registered")
            ASPEC.compile_time_assert(\{{ command["parameters"]["user_classes"]["value"].stringify == %(["Athena::Security::User::InMemory", "strong"] of String) }}, "Expected the configured user classes")
          end
        end
      CR
    end

    it "errors if the algorithm is not supported" do
      assert_compile_time_error "The 'argon2id' algorithm of the 'Athena::Security::User::InMemory' password hasher is not supported. Expected one of: auto, bcrypt, native.", <<-'CR'
        ADI.configure({
          security: {
            password_hashers: {ASEC::User::InMemory => :argon2id},
            firewalls:        {main: {security: true}},
          },
        })
      CR
    end

    it "errors if the cost is out of range" do
      assert_compile_time_error "The 'cost' of the 'strong' password hasher must be in the range of 4..31, got '32'.", <<-'CR'
        ADI.configure({
          security: {
            password_hashers: {"strong" => {cost: 32}},
            firewalls:        {main: {security: true}},
          },
        })
      CR
    end

    it "errors if a password hasher migrates from an unknown hasher" do
      assert_compile_time_error "The 'strong' password hasher migrates from 'missing', which is neither a configured password hasher nor a supported algorithm.", <<-'CR'
        ADI.configure({
          security: {
            password_hashers: {"strong" => {migrate_from: ["missing"]}},
            firewalls:        {main: {security: true}},
          },
        })
      CR
    end
  end

  describe "authorization" do
    it "registers the voters" do
      assert_compiles <<-'CR'
        @[ADI::Register]
        class AppVoter < ASEC::Authorization::Voter
          include ASEC::Authorization::Voter::AttributeOnly

          def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
            ASEC::Authorization::Voter::Access::Abstain
          end

          def supports_attribute?(attribute : String) : Bool
            false
          end
        end

        ADI.configure({
          security: {
            firewalls: {main: {security: true}},
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              adm = sh["athena_security_access_decision_manager"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ adm["voters"]["value"].map(&.stringify) == ["athena_security_access_authenticated_voter", "athena_security_access_simple_role_voter", "app_voter"] }}, "Expected the built-in voters before the application voters")
            ASPEC.compile_time_assert(\{{ adm["strategy"]["value"].stringify == "Athena::Security::Authorization::Strategy::Affirmative.new(false)" }}, "Expected the affirmative strategy by default")
            ASPEC.compile_time_assert(\{{ sh["athena_security_role_hierarchy"] == nil }}, "Expected no role hierarchy")
          end
        end
      CR
    end

    it "registers the role hierarchy and strategy" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls:               {main: {security: true}},
            role_hierarchy:          {"ROLE_ADMIN" => ["ROLE_USER"]},
            access_decision_manager: {strategy: :consensus, allow_if_all_abstain: true, allow_if_equal_granted_denied: false},
          },
        })

        macro finished
          macro finished
            \{%
              sh = ADI::ServiceContainer::SERVICE_HASH
              adm = sh["athena_security_access_decision_manager"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ adm["voters"]["value"].map(&.stringify) == ["athena_security_access_authenticated_voter", "athena_security_access_role_hierarchy_voter"] }}, "Expected the role hierarchy voter")
            ASPEC.compile_time_assert(\{{ adm["strategy"]["value"].stringify == "Athena::Security::Authorization::Strategy::Consensus.new(true, false)" }}, "Expected the configured strategy")
            ASPEC.compile_time_assert(\{{ sh["athena_security_role_hierarchy"]["parameters"]["hierarchy"]["value"].stringify == %({"ROLE_ADMIN" => ["ROLE_USER"]} of String => Array(String)) }}, "Expected the configured role hierarchy")
          end
        end
      CR
    end

    it "registers the unanimous strategy" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls:               {main: {security: true}},
            access_decision_manager: {strategy: :unanimous},
          },
        })

        macro finished
          macro finished
            \{% strategy = ADI::ServiceContainer::SERVICE_HASH["athena_security_access_decision_manager"]["parameters"]["strategy"]["value"] %}
            ASPEC.compile_time_assert(\{{ strategy.stringify == "Athena::Security::Authorization::Strategy::Unanimous.new(false)" }}, "Expected the unanimous strategy")
          end
        end
      CR
    end

    it "registers the priority strategy" do
      assert_compiles <<-'CR'
        ADI.configure({
          security: {
            firewalls:               {main: {security: true}},
            access_decision_manager: {strategy: :priority, allow_if_all_abstain: true},
          },
        })

        macro finished
          macro finished
            \{% strategy = ADI::ServiceContainer::SERVICE_HASH["athena_security_access_decision_manager"]["parameters"]["strategy"]["value"] %}
            ASPEC.compile_time_assert(\{{ strategy.stringify == "Athena::Security::Authorization::Strategy::Priority.new(true)" }}, "Expected the priority strategy")
          end
        end
      CR
    end

    it "errors if the strategy is not supported" do
      assert_compile_time_error "The strategy 'majority' is not supported. Expected one of: affirmative, consensus, unanimous, priority.", <<-'CR'
        ADI.configure({
          security: {
            firewalls:               {main: {security: true}},
            access_decision_manager: {strategy: :majority},
          },
        })
      CR
    end
  end
end
