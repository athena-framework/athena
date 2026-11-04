require "./spec_helper"

describe ASEC::Bundle, tags: "compiled" do
  it "authenticates and authorizes the requests of a framework application" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "athena"
      require "athena/spec"
      require "../../src/bundle"

      @[ADI::Register]
      class APITokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
        def supports?(request : AHTTP::Request) : Bool?
          request.headers.has_key? "x-api-token"
        end

        def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
          ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new(request.headers["x-api-token"])
        end

        def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
          nil
        end

        def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
          AHTTP::Response.new exception.message_key, :unauthorized
        end
      end

      @[ADI::Register]
      class PasswordAuthenticator < ASEC::Authenticator::AbstractAuthenticator
        def supports?(request : AHTTP::Request) : Bool?
          request.method == "POST"
        end

        def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
          ASEC::Authenticator::Passport.new(
            ASEC::Authenticator::Passport::Badge::User.new(request.headers["x-username"]),
            ASEC::Authenticator::Passport::Credentials::Password.new(request.headers["x-password"]),
          )
        end

        def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
          AHTTP::Response.new "Logged in as #{token.user_identifier} on #{firewall_name}."
        end

        def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
          AHTTP::Response.new exception.message_key, :unauthorized
        end
      end

      # Provides `john`, whose password is hashed with a lower cost than configured, and records the upgrades of its password.
      @[ADI::Register]
      class AppUserProvider
        include ASEC::User::Provider::Interface
        include ASEC::User::PasswordUpgraderInterface

        class_getter upgraded_passwords = [] of String

        def load_user_by_identifier(identifier : String) : ASEC::User::Interface
          raise ASEC::Exception::UserNotFound.new(user_identifier: identifier) unless identifier == "john"

          ASEC::User::InMemory.new "john", "$2a$04$wHvL8qlvbtcvO/mNFw1p4e4L5wnOCWNfIWYqKTz5lPAI0KpjdUmzq", ["ROLE_USER"]
        end

        def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
          user
        end

        def supports_class?(klass : ASEC::User::Interface.class) : Bool
          klass == ASEC::User::InMemory
        end

        def upgrade_password(user : APH::PasswordAuthenticatedUserInterface, new_hashed_password : String) : Nil
          @@upgraded_passwords << new_hashed_password
        end
      end

      @[ADI::Register]
      class LoginRecorder
        class_getter logins = [] of String

        @[AEDA::AsEventListener]
        def on_login_success(event : ASEC::Events::LoginSuccess) : Nil
          @@logins << "#{event.firewall_name}:#{event.user.user_identifier}"
        end
      end

      @[ADI::Register]
      class SecretVoter < ASEC::Authorization::Voter
        include ASEC::Authorization::Voter::AttributeOnly

        def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
          token.user_identifier == "admin" ? ASEC::Authorization::Voter::Access::Granted : ASEC::Authorization::Voter::Access::Denied
        end

        def supports_attribute?(attribute : String) : Bool
          attribute == "SECRET"
        end
      end

      ADI.configure({
        security: {
          password_hashers: {
            ASEC::User::InMemory => {cost: 5},
          },
          providers: {
            in_memory: {
              memory: {
                users: {
                  "admin" => {password: nil, roles: ["ROLE_ADMIN"]},
                  "user"  => {password: nil, roles: ["ROLE_USER"]},
                },
              },
            },
            app: {id: "app_user_provider"},
          },
          firewalls: {
            public: {pattern: /^\/public/, security: false},
            login:  {pattern: /^\/login/, provider: "app", custom_authenticators: ["password_authenticator"]},
            main:   {pattern: /^\/api/, provider: "in_memory", custom_authenticators: ["api_token_authenticator"]},
          },
          access_control: [
            {path: /^\/api\/admin/, role: "ROLE_ADMIN"},
            {path: /^\/api\/secret/, role: "SECRET"},
            {path: /^\/api/, role: "IS_AUTHENTICATED"},
          ],
          role_hierarchy: {"ROLE_ADMIN" => ["ROLE_USER"]},
        },
      })

      @[ADI::Register(public: true)]
      class SecuredController < ATH::Controller
        def initialize(@token_storage : ASEC::Authentication::Token::Storage::Interface, @checker : ASEC::Authorization::CheckerInterface); end

        @[ARTA::Get("/api/me")]
        def me : String
          "#{@token_storage.token.try(&.user_identifier)} #{@checker.granted?("ROLE_USER")}"
        end

        @[ARTA::Get("/api/admin")]
        def admin : String
          "admin"
        end

        @[ARTA::Get("/api/secret")]
        def secret : String
          "secret"
        end

        @[ARTA::Get("/public")]
        def public_page : String
          "public #{@token_storage.token.nil?}"
        end

        # Never called, as the authenticator of the firewall returns a response.
        @[ARTA::Post("/login")]
        def login : String
          "login"
        end
      end

      struct SecurityBundleTest < ATH::Spec::APITestCase
        def test_authenticated : Nil
          self.get "/api/me", headers: HTTP::Headers{"x-api-token" => "user"}

          self.assert_response_is_successful
          self.response.body.should eq %("user true")
          LoginRecorder.logins.last.should eq "main:user"
        end

        def test_role_hierarchy : Nil
          self.get "/api/me", headers: HTTP::Headers{"x-api-token" => "admin"}
          self.response.body.should eq %("admin true")

          self.get "/api/admin", headers: HTTP::Headers{"x-api-token" => "admin"}
          self.assert_response_is_successful
        end

        def test_access_denied : Nil
          self.get "/api/admin", headers: HTTP::Headers{"x-api-token" => "user"}

          self.assert_response_has_status :forbidden
        end

        def test_application_voter : Nil
          self.get "/api/secret", headers: HTTP::Headers{"x-api-token" => "user"}
          self.assert_response_has_status :forbidden

          self.get "/api/secret", headers: HTTP::Headers{"x-api-token" => "admin"}
          self.assert_response_is_successful
        end

        def test_unauthenticated : Nil
          self.get "/api/me"

          self.assert_response_has_status :unauthorized
        end

        def test_unknown_user : Nil
          self.get "/api/me", headers: HTTP::Headers{"x-api-token" => "nobody"}

          self.assert_response_has_status :unauthorized
          self.response.body.should eq "Invalid credentials."
        end

        def test_security_disabled : Nil
          self.get "/public", headers: HTTP::Headers{"x-api-token" => "admin"}

          self.assert_response_is_successful
          self.response.body.should eq %("public true")
        end

        def test_password_login_upgrades_the_password : Nil
          self.post "/login", headers: HTTP::Headers{"x-username" => "john", "x-password" => "password"}

          self.assert_response_is_successful
          self.response.body.should eq "Logged in as john on login."
          LoginRecorder.logins.last.should eq "login:john"
          AppUserProvider.upgraded_passwords.size.should eq 1

          upgraded_password = AppUserProvider.upgraded_passwords.first
          hasher = APH::Native.new cost: 5
          hasher.needs_rehash?(upgraded_password).should be_false
          hasher.verify(upgraded_password, "password").should be_true
        end

        def test_password_login_with_an_invalid_password : Nil
          self.post "/login", headers: HTTP::Headers{"x-username" => "john", "x-password" => "wrong"}

          self.assert_response_has_status :unauthorized
          self.response.body.should eq "Invalid credentials."
        end
      end

      ASPEC.run_all
    CR
  end
end
