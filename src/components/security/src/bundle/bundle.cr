# Integrates the Security component with the [dependency injection](/DependencyInjection/) and [HTTP kernel](/HTTPKernel/) components, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-security/bundle` to register the bundle, then configure at least one firewall:
#
# ```
# require "athena"
# require "athena-security/bundle"
#
# ADI.configure({
#   security: {
#     password_hashers: {
#       ASEC::User::InMemory => :auto,
#     },
#     providers: {
#       users_in_memory: {
#         memory: {
#           users: {"admin" => {password: "$2y$13$...", roles: ["ROLE_ADMIN"]}},
#         },
#       },
#     },
#     firewalls: {
#       main: {
#         pattern:               /^\/api/,
#         custom_authenticators: ["api_token_authenticator"],
#       },
#     },
#     access_control: [
#       {path: /^\/api\/admin/, role: "ROLE_ADMIN"},
#       {path: /^\/api/, role: "IS_AUTHENTICATED"},
#     ],
#   },
# })
# ```
#
# See `Schema` for the full set of possible configuration options.
#
# Each request belongs to the first firewall matching it, which authenticates its user via the custom authenticators of the firewall, see `ASEC::Authenticator::Interface`.
# The users are loaded via the provider of the firewall, which defaults to the only configured provider.
# The `access_control` rules then require an attribute for the requests they match, e.g. a role.
#
# Services inheriting from `ASEC::Authorization::Voter` are automatically used to decide the access of users, e.g. via the `ASEC::Authorization::CheckerInterface` service.
# Listeners of `ASEC::Events` handle the events of every firewall.
@[ADI::Bundle("security")]
struct Athena::Security::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [
    {Athena::Security::Bundle::CompilerPasses::RegisterEntryPoints, :before_optimization, 99},
    {Athena::Security::Bundle::CompilerPasses::RegisterGlobalSecurityEventListeners, :before_removing, -10},
  ]

  # :nodoc:
  #
  # Creates the password hasher factory, as the free variables of `APH::Factory.new` cannot be resolved when wiring services.
  def self.password_hasher_factory(password_hashers : Hash(String, APH::Interface)) : APH::Factory
    APH::Factory.new password_hashers
  end

  # Represents the possible properties used to configure and customize the security integration.
  # See the [Getting Started](/getting_started/configuration) docs for more information on how the bundle system works in Athena.
  module Schema
    include ADI::Extension::Schema

    # The password hashers of each type of user, keyed by the type, or by the name an `APH::PasswordHasherAwareInterface` user returns.
    # A hasher may also be configured by its *algorithm* alone, e.g. `ASEC::User::InMemory => :auto`.
    #
    # ```
    # password_hashers: {
    #   User                 => {algorithm: :auto, cost: 12},
    #   ASEC::User::InMemory => :auto,
    #   "legacy"             => {id: "legacy_password_hasher"},
    # }
    # ```
    #
    # ---
    # >>algorithm: The algorithm hashing the passwords: `:auto`, `:bcrypt`, or `:native`, which all use bcrypt via `APH::Native`.
    # >>cost: The cost of the bcrypt algorithm, in the range of `APH::Native::COST_RANGE`. Defaults to the default cost of `APH::Native`.
    # >>migrate_from: The names of other password hashers, or algorithms, whose hashed passwords are still verified, and upgraded once their user logs in, see `APH::Migrating`.
    # >>id: The ID of a service including `APH::Interface` to use instead.
    # ---
    map_of password_hashers,
      algorithm : Symbol = :auto,
      cost : Int32? = nil,
      migrate_from : Array(String) = [] of String,
      id : String? = nil

    # Users kept in memory, see `ASEC::User::Provider::InMemory`.
    #
    # ---
    # >>users: The users, keyed by their identifier, each with its hashed *password* and its *roles*.
    # ---
    object_schema Memory,
      users : Hash(String, NamedTuple(password: String?, roles: Array(String)))? = nil

    # Loads users from multiple providers in turn, see `ASEC::User::Provider::Chain`.
    #
    # ---
    # >>providers: The names of the providers.
    # ---
    object_schema Chain,
      providers : Array(String)? = nil

    # The user providers, keyed by their name, each configured via exactly one of *id*, *memory*, or *chain*.
    #
    # ---
    # >>id: The ID of a service including `ASEC::User::Provider::Interface`.
    # >>memory: Provides the users kept in memory, see `Memory`.
    # >>chain: Provides the users of other providers, see `Chain`.
    # ---
    map_of providers,
      id : String? = nil,
      memory : Memory = {users: nil},
      chain : Chain = {providers: nil}

    # The firewalls, keyed by their name.
    # A request belongs to the first firewall matching it, while a firewall without *pattern*, *host*, or *request_matcher* matches every request.
    #
    # ---
    # >>pattern: Matches the requests whose path matches this regex.
    # >>host: Matches the requests whose host matches this regex.
    # >>methods: Only matches the requests using one of these methods, along with *pattern* or *host*.
    # >>request_matcher: The ID of a service including `AHTTP::RequestMatcher::Interface` matching the requests, instead of *pattern*, *host*, and *methods*.
    # >>security: Whether security is enabled on the firewall, otherwise its requests are neither authenticated nor checked by `access_control` rules.
    # >>provider: The name of the user provider loading the users being authenticated, which defaults to the only configured provider.
    # >>user_checker: The ID of a service including `ASEC::User::Checker::Interface` checking the account of the users being authenticated. Defaults to an `ASEC::User::Checker::InMemory`.
    # >>entry_point: The ID of a service including `ASEC::EntryPoint::Interface` starting the authentication of users who must authenticate, which defaults to the only custom authenticator that includes it.
    # Without one, these users get a `401` response.
    # >>custom_authenticators: The IDs of the services including `ASEC::Authenticator::Interface` authenticating the requests.
    # ---
    map_of firewalls,
      pattern : Regex? = nil,
      host : Regex? = nil,
      methods : Array(String) = [] of String,
      request_matcher : String? = nil,
      security : Bool = true,
      provider : String? = nil,
      user_checker : String? = nil,
      entry_point : String? = nil,
      custom_authenticators : Array(String) = [] of String

    # The rules requiring an attribute for the requests of firewalls, e.g. a role.
    # A request requires the attribute of the first rule matching it, while a rule without *path*, *host*, *methods*, or *request_matcher* matches every request.
    #
    # ```
    # access_control: [
    #   {path: /^\/admin\/login/, role: "PUBLIC_ACCESS"},
    #   {path: /^\/admin/, role: "ROLE_ADMIN"},
    # ]
    # ```
    #
    # ---
    # >>path: Matches the requests whose path matches this regex.
    # >>host: Matches the requests whose host matches this regex.
    # >>methods: Only matches the requests using one of these methods.
    # >>request_matcher: The ID of a service including `AHTTP::RequestMatcher::Interface` matching the requests, instead of *path*, *host*, and *methods*.
    # >>role: The attribute the requests require, or `nil` to require nothing, e.g. to exclude them from a later rule.
    # ---
    array_of access_control,
      path : Regex? = nil,
      host : Regex? = nil,
      methods : Array(String) = [] of String,
      request_matcher : String? = nil,
      role : String? = nil

    # The roles granted by other roles, see `ASEC::Role::Hierarchy`.
    #
    # ```
    # role_hierarchy: {
    #   "ROLE_ADMIN"       => ["ROLE_USER"],
    #   "ROLE_SUPER_ADMIN" => ["ROLE_ADMIN"],
    # }
    # ```
    property role_hierarchy : Hash(String, Array(String)) = {} of String => Array(String)

    # Determines which authentication errors are shown to users, see `ASEC::Authentication::ExposeSecurityLevel`.
    property expose_security_errors : ASEC::Authentication::ExposeSecurityLevel = :none

    # Configures how the votes of the voters turn into a decision.
    module AccessDecisionManager
      include ADI::Extension::Schema

      # The strategy turning the votes into a decision: `:affirmative`, `:consensus`, `:unanimous`, or `:priority`.
      # See `ASEC::Authorization::Strategy::Interface`.
      property strategy : Symbol = :affirmative

      # Whether the access is granted if all voters abstained.
      property allow_if_all_abstain : Bool = false

      # Whether the access is granted if as many voters grant as deny it, with the `:consensus` strategy.
      property allow_if_equal_granted_denied : Bool = true
    end
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            cfg = CONFIG["security"]

            # Voters are used by the access decision manager.
            AUTO_CONFIGURATIONS[Athena::Security::Authorization::Voter] = {
              tags: ["security.voter"],
            }

            SERVICE_HASH[token_storage_id = "athena_security_token_storage"] = {
              class: Athena::Security::Authentication::Token::Storage,
            }

            ALIASES[Athena::Security::Authentication::Token::Storage::Interface] = [
              {id: token_storage_id, public: false},
            ]

            SERVICE_HASH[trust_resolver_id = "athena_security_authentication_trust_resolver"] = {
              class: Athena::Security::Authentication::TrustResolver,
            }

            ALIASES[Athena::Security::Authentication::TrustResolverInterface] = [
              {id: trust_resolver_id, public: false},
            ]

            SERVICE_HASH[user_checker_id = "athena_security_user_checker"] = {
              class: Athena::Security::User::Checker::InMemory,
            }

            ALIASES[Athena::Security::User::Checker::Interface] = [
              {id: user_checker_id, public: false},
            ]

            # Authorization

            SERVICE_HASH["athena_security_access_authenticated_voter"] = {
              class:      Athena::Security::Authorization::Voter::Authenticated,
              parameters: {
                authentication_trust_resolver: {value: "@#{trust_resolver_id.id}"},
              },
            }

            if cfg["role_hierarchy"].empty?
              SERVICE_HASH["athena_security_access_simple_role_voter"] = {
                class: Athena::Security::Authorization::Voter::Role,
              }
            else
              SERVICE_HASH[role_hierarchy_id = "athena_security_role_hierarchy"] = {
                class:      Athena::Security::Role::Hierarchy,
                parameters: {
                  hierarchy: {value: "#{cfg["role_hierarchy"]} of String => Array(String)".id},
                },
              }

              ALIASES[Athena::Security::Role::HierarchyInterface] = [
                {id: role_hierarchy_id, public: false},
              ]

              SERVICE_HASH["athena_security_access_role_hierarchy_voter"] = {
                class:      Athena::Security::Authorization::Voter::RoleHierarchy,
                parameters: {
                  role_hierarchy: {value: "@#{role_hierarchy_id.id}"},
                },
              }
            end

            adm_cfg = cfg["access_decision_manager"]
            allow_if_all_abstain = adm_cfg["allow_if_all_abstain"]

            strategy = if adm_cfg["strategy"] == :affirmative
                         "Athena::Security::Authorization::Strategy::Affirmative.new(#{allow_if_all_abstain})"
                       elsif adm_cfg["strategy"] == :consensus
                         "Athena::Security::Authorization::Strategy::Consensus.new(#{allow_if_all_abstain}, #{adm_cfg["allow_if_equal_granted_denied"]})"
                       elsif adm_cfg["strategy"] == :unanimous
                         "Athena::Security::Authorization::Strategy::Unanimous.new(#{allow_if_all_abstain})"
                       elsif adm_cfg["strategy"] == :priority
                         "Athena::Security::Authorization::Strategy::Priority.new(#{allow_if_all_abstain})"
                       else
                         adm_cfg["strategy"].raise "The strategy '#{adm_cfg["strategy"].id}' is not supported. Expected one of: affirmative, consensus, unanimous, priority."
                       end

            SERVICE_HASH[access_decision_manager_id = "athena_security_access_decision_manager"] = {
              class:      Athena::Security::Authorization::AccessDecisionManager,
              parameters: {
                voters:   {value: "!security.voter"},
                strategy: {value: strategy.id},
              },
            }

            SERVICE_HASH[authorization_checker_id = "athena_security_authorization_checker"] = {
              class:      Athena::Security::Authorization::Checker,
              parameters: {
                token_storage:           {value: "@#{token_storage_id.id}"},
                access_decision_manager: {value: "@#{access_decision_manager_id.id}"},
              },
            }

            ALIASES[Athena::Security::Authorization::CheckerInterface] = [
              {id: authorization_checker_id, public: false},
            ]

            # Password hashers

            # As `{key, name, hasher configuration}`.
            password_hashers = [] of Nil

            cfg["password_hashers"].to_a.reject { |(key, _)| key.stringify == "__nil" }.each do |(key, hasher)|
              # A hasher configured by its algorithm alone.
              hasher = {algorithm: hasher} if hasher.is_a?(SymbolLiteral)

              # Types are keyed by their fully qualified name, which `APH::Factory` matches the type of users against.
              key_name = key.is_a?(StringLiteral) ? key.id.stringify : key.resolve.name.stringify

              password_hashers << {key, key_name, hasher}
            end

            # The hashers configured via a service, which are provided as raw code.
            hasher_service_ids = [] of Nil

            # The code creating the hasher of each password hasher, keyed by its name.
            hashers = [] of Nil

            cost_range = Athena::PasswordHasher::Native::COST_RANGE.resolve

            password_hashers.each do |(key, key_name, hasher)|
              algorithm = hasher["algorithm"] || :auto
              cost = hasher["cost"]
              migrate_from = hasher["migrate_from"] || [] of Nil

              if cost != nil && !cost_range.to_a.includes?(cost)
                cost.raise "The 'cost' of the '#{key_name.id}' password hasher must be in the range of #{cost_range}, got '#{cost}'."
              end

              if !hasher["id"] && !{:auto, :bcrypt, :native}.includes?(algorithm)
                algorithm.raise "The '#{algorithm.id}' algorithm of the '#{key_name.id}' password hasher is not supported. Expected one of: auto, bcrypt, native."
              end

              hasher_code = if id = hasher["id"]
                              hasher_service_ids << id
                              id.id
                            elsif cost == nil
                              "APH::Native.new".id
                            else
                              "APH::Native.new(cost: #{cost})".id
                            end

              unless migrate_from.empty?
                extra_hashers = migrate_from.map do |name|
                  other = password_hashers.find { |(_, other_name, _)| other_name == name }

                  if other && (other_id = other[2]["id"])
                    hasher_service_ids << other_id
                    other_id.id
                  elsif other && other[2]["cost"] != nil
                    "APH::Native.new(cost: #{other[2]["cost"]})".id
                  elsif other || {"auto", "bcrypt", "native"}.includes?(name)
                    "APH::Native.new".id
                  else
                    name.raise "The '#{key_name.id}' password hasher migrates from '#{name.id}', which is neither a configured password hasher nor a supported algorithm."
                  end
                end

                hasher_code = "APH::Migrating.new(#{hasher_code}, #{extra_hashers.join(", ").id})".id
              end

              hashers << "#{key_name} => #{hasher_code}"
            end

            hasher_keys = password_hashers.map { |(_, key_name, _)| key_name }

            SERVICE_HASH[password_hasher_factory_id = "athena_security_password_hasher_factory"] = {
              class:               Athena::PasswordHasher::Factory,
              factory:             {Athena::Security::Bundle, "password_hasher_factory"},
              referenced_services: hasher_service_ids,
              parameters:          {
                password_hashers: {value: "{#{hashers.join(", ").id}} of String => APH::Interface".id},
              },
            }

            ALIASES[Athena::PasswordHasher::FactoryInterface] = [
              {id: password_hasher_factory_id, public: false},
            ]

            SERVICE_HASH[user_password_hasher_id = "athena_security_user_password_hasher"] = {
              class:      Athena::PasswordHasher::UserPasswordHasher,
              parameters: {
                hasher_factory: {value: "@#{password_hasher_factory_id.id}"},
              },
            }

            ALIASES[Athena::PasswordHasher::UserPasswordHasherInterface] = [
              {id: user_password_hasher_id, public: false},
            ]

            # Requiring the Console component alone does not register its bundle, so check for the bundle to know commands are registered.
            if ADI::ServiceContainer::EXTENSIONS["console"]
              SERVICE_HASH["athena_security_command_user_password_hash"] = {
                class:      Athena::PasswordHasher::Commands::UserPasswordHash,
                parameters: {
                  hasher_factory: {value: "@#{password_hasher_factory_id.id}"},
                  user_classes:   {value: "#{hasher_keys} of String".id},
                },
              }
            end

            SERVICE_HASH["athena_security_listener_check_authenticator_credentials"] = {
              class:      Athena::Security::Listeners::CheckCredentials,
              parameters: {
                hasher_factory: {value: "@#{password_hasher_factory_id.id}"},
              },
            }

            SERVICE_HASH["athena_security_listener_password_migrating"] = {
              class:      Athena::Security::Listeners::PasswordMigrating,
              parameters: {
                hasher_factory: {value: "@#{password_hasher_factory_id.id}"},
              },
            }

            # User providers

            providers = cfg["providers"].to_a.reject { |(name, _)| name.stringify == "__nil" }

            # The ID of the service of each provider, keyed by its name.
            provider_ids = {} of Nil => Nil

            providers.each do |(name, provider)|
              types = [provider["id"], provider["memory"]["users"], provider["chain"]["providers"]].reject(&.nil?)

              if types.empty?
                name.raise "You must set a provider definition for the '#{name.id}' provider."
              end

              if types.size > 1
                name.raise "You cannot set multiple provider types for the '#{name.id}' provider."
              end

              provider_ids[name.stringify] = provider["id"] || "athena_security_user_provider_#{name.id}"
            end

            providers.each do |(name, provider)|
              if users = provider["memory"]["users"]
                in_memory_users = users.map do |identifier, user|
                  roles = user["roles"] || [] of Nil

                  "Athena::Security::User::InMemory.new(#{identifier}, #{user["password"]}, #{roles.empty? ? "[] of String".id : roles})"
                end

                SERVICE_HASH[provider_ids[name.stringify]] = {
                  class:      Athena::Security::User::Provider::InMemory,
                  parameters: {
                    users: {value: "[#{in_memory_users.join(", ").id}] of Athena::Security::User::InMemory".id},
                  },
                }
              elsif chained_providers = provider["chain"]["providers"]
                chained_provider_ids = chained_providers.map do |chained_provider|
                  unless chained_provider_id = provider_ids[chained_provider]
                    chained_provider.raise "The '#{name.id}' provider chains the '#{chained_provider.id}' provider, which is not configured."
                  end

                  "@#{chained_provider_id.id}"
                end

                SERVICE_HASH[provider_ids[name.stringify]] = {
                  class:      Athena::Security::User::Provider::Chain,
                  parameters: {
                    providers: {value: chained_provider_ids.empty? ? "[] of Athena::Security::User::Provider::Interface".id : chained_provider_ids},
                  },
                }
              end
            end

            # Request matchers, shared between the firewalls and the access control rules matching the same requests.

            request_matcher_ids = {} of Nil => Nil

            # Access control

            access_map_calls = [] of Nil

            cfg["access_control"].each_with_index do |rule, idx|
              matcher_code = if rule["request_matcher"]
                               if rule["path"] || rule["host"] || !rule["methods"].empty?
                                 rule["request_matcher"].raise "The 'request_matcher' option of an 'access_control' rule cannot be specified alongside other request matching options. Consider integrating your constraints inside your request matcher directly."
                               end

                               rule["request_matcher"].id
                             else
                               matcher_key = {rule["path"], rule["host"], rule["methods"]}.symbolize

                               unless matcher_id = request_matcher_ids[matcher_key]
                                 matchers = [] of Nil
                                 matchers << "AHTTP::RequestMatcher::Path.new(#{rule["path"]})".id if rule["path"]
                                 matchers << "AHTTP::RequestMatcher::Hostname.new(#{rule["host"]})".id if rule["host"]
                                 matchers << "AHTTP::RequestMatcher::Method.new(#{rule["methods"]})".id unless rule["methods"].empty?

                                 SERVICE_HASH[matcher_id = "athena_security_request_matcher_#{request_matcher_ids.size}"] = {
                                   class:      AHTTP::RequestMatcher,
                                   parameters: {
                                     matchers: {value: "#{matchers} of AHTTP::RequestMatcher::Interface".id},
                                   },
                                 }

                                 request_matcher_ids[matcher_key] = matcher_id
                               end

                               matcher_id.id
                             end

              access_map_calls << {"add", {matcher_code, rule["role"]}}
            end

            SERVICE_HASH[access_map_id = "athena_security_access_map"] = {
              class:               Athena::Security::AccessMap,
              calls:               access_map_calls,
              referenced_services: access_map_calls.map { |(_, args)| args[0].stringify },
            }

            SERVICE_HASH[access_listener_id = "athena_security_access_listener"] = {
              class:      Athena::Security::Firewall::AccessListener,
              parameters: {
                token_storage:           {value: "@#{token_storage_id.id}"},
                access_decision_manager: {value: "@#{access_decision_manager_id.id}"},
                access_map:              {value: "@#{access_map_id.id}"},
              },
            }

            # Firewalls

            firewalls = cfg["firewalls"].to_a.reject { |(name, _)| name.stringify == "__nil" }

            if firewalls.empty?
              cfg.raise "The 'security.firewalls' option must define at least one firewall."
            end

            # The context of each firewall, keyed by its name.
            contexts = {} of Nil => Nil

            # The code of the request matcher of each firewall, keyed by its name, matching every request if `nil`.
            request_matchers = [] of Nil

            # The request matchers are provided as raw code, so they are referenced explicitly.
            request_matcher_service_ids = [] of Nil

            firewalls.each do |(name, firewall)|
              matcher_code = if firewall["request_matcher"]
                               firewall["request_matcher"].id
                             elsif firewall["pattern"] || firewall["host"]
                               matcher_key = {firewall["pattern"], firewall["host"], firewall["methods"]}.symbolize

                               unless matcher_id = request_matcher_ids[matcher_key]
                                 matchers = [] of Nil
                                 matchers << "AHTTP::RequestMatcher::Path.new(#{firewall["pattern"]})".id if firewall["pattern"]
                                 matchers << "AHTTP::RequestMatcher::Hostname.new(#{firewall["host"]})".id if firewall["host"]
                                 matchers << "AHTTP::RequestMatcher::Method.new(#{firewall["methods"]})".id unless firewall["methods"].empty?

                                 SERVICE_HASH[matcher_id = "athena_security_request_matcher_#{request_matcher_ids.size}"] = {
                                   class:      AHTTP::RequestMatcher,
                                   parameters: {
                                     matchers: {value: "#{matchers} of AHTTP::RequestMatcher::Interface".id},
                                   },
                                 }

                                 request_matcher_ids[matcher_key] = matcher_id
                               end

                               matcher_id.id
                             end

              context_id = "athena_security_firewall_context_#{name}"

              if !firewall["security"]
                SERVICE_HASH[context_id] = {
                  class:      Athena::Security::Bundle::FirewallContext,
                  parameters: {
                    listeners:          {value: "[] of Athena::Security::Firewall::ListenerInterface".id},
                    exception_listener: {value: nil},
                  },
                }
              else
                firewall_event_dispatcher_id = "athena_security_event_dispatcher_#{name}"

                SERVICE_HASH[firewall_event_dispatcher_id] = {
                  class: Athena::EventDispatcher::EventDispatcher,
                }

                # The provider of the firewall, which must be configured explicitly if more than one provider is configured.
                provider_id = if provider = firewall["provider"]
                                provider_ids[provider] || provider.raise "Invalid firewall '#{name.id}': user provider '#{provider.id}' not found."
                              elsif provider_ids.size == 1
                                provider_ids.values.first
                              elsif provider_ids.size > 1 && !firewall["custom_authenticators"].empty?
                                name.raise "Not configuring explicitly the provider for the 'custom_authenticators' authenticator on '#{name.id}' firewall is ambiguous as there is more than one registered provider. Set the 'provider' key to one of the configured providers, even if your custom authenticators don't use it."
                              end

                if provider_id
                  SERVICE_HASH["athena_security_listener_#{name}_user_provider"] = {
                    class:      Athena::Security::Listeners::UserProvider,
                    tags:       [{name: "event_dispatcher.listener", dispatcher: firewall_event_dispatcher_id}],
                    parameters: {
                      user_provider: {value: "@#{provider_id.id}"},
                    },
                  }
                end

                SERVICE_HASH["athena_security_listener_#{name}_user_checker"] = {
                  class:      Athena::Security::Listeners::UserChecker,
                  tags:       [{name: "event_dispatcher.listener", dispatcher: firewall_event_dispatcher_id}],
                  parameters: {
                    user_checker: {value: "@#{(firewall["user_checker"] || user_checker_id).id}"},
                  },
                }

                authenticators = firewall["custom_authenticators"].map { |authenticator_id| "@#{authenticator_id.id}" }

                SERVICE_HASH[authenticator_manager_id = "athena_security_authenticator_manager_#{name}"] = {
                  class:      Athena::Security::Authentication::AuthenticatorManager,
                  parameters: {
                    authenticators:         {value: authenticators.empty? ? "[] of Athena::Security::Authenticator::Interface".id : authenticators},
                    token_storage:          {value: "@#{token_storage_id.id}"},
                    event_dispatcher:       {value: "@#{firewall_event_dispatcher_id.id}"},
                    firewall_name:          {value: name.stringify},
                    expose_security_errors: {value: cfg["expose_security_errors"]},
                  },
                }

                SERVICE_HASH[authenticator_listener_id = "athena_security_firewall_authenticator_#{name}"] = {
                  class:      Athena::Security::Firewall::AuthenticatorManagerListener,
                  parameters: {
                    authenticator_manager: {value: "@#{authenticator_manager_id.id}"},
                  },
                }

                # The entry point defaults to the custom authenticator including `ASEC::EntryPoint::Interface`, see `CompilerPasses::RegisterEntryPoints`.
                SERVICE_HASH[exception_listener_id = "athena_security_exception_listener_#{name}"] = {
                  class:      Athena::Security::Firewall::ExceptionListener,
                  parameters: {
                    token_storage:                 {value: "@#{token_storage_id.id}"},
                    authentication_trust_resolver: {value: "@#{trust_resolver_id.id}"},
                    firewall_name:                 {value: name.stringify},
                    authentication_entry_point:    {value: firewall["entry_point"] ? "@#{firewall["entry_point"].id}" : nil},
                  },
                }

                SERVICE_HASH[context_id] = {
                  class:      Athena::Security::Bundle::FirewallContext,
                  parameters: {
                    listeners:          {value: ["@#{authenticator_listener_id.id}", "@#{access_listener_id.id}"]},
                    exception_listener: {value: "@#{exception_listener_id.id}"},
                  },
                }
              end

              contexts[name.stringify] = "@#{context_id.id}"

              if matcher_code
                request_matchers << "#{name.stringify} => #{matcher_code}"
                request_matcher_service_ids << matcher_code.stringify
              else
                request_matchers << "#{name.stringify} => nil"
              end
            end

            SERVICE_HASH[firewall_map_id = "athena_security_firewall_map"] = {
              class:               Athena::Security::Bundle::FirewallMap,
              referenced_services: request_matcher_service_ids,
              parameters:          {
                # The contexts are only instantiated once a request belongs to their firewall.
                contexts: {value: contexts},
                map:      {value: "{#{request_matchers.join(", ").id}} of String => AHTTP::RequestMatcher::Interface?".id},
              },
            }

            ALIASES[Athena::Security::FirewallMapInterface] = [
              {id: firewall_map_id, public: false},
            ]

            SERVICE_HASH["athena_security_firewall"] = {
              class:      Athena::Security::Firewall,
              parameters: {
                map: {value: "@#{firewall_map_id.id}"},
              },
            }
          %}
        {% end %}
      end
    end
  end
end
