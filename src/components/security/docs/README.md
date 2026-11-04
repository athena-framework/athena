The `Athena::Security` component provides the building blocks to authenticate users and decide what they are allowed to do:

* Users, represented by an [ASEC::User::Interface](/Security/User/Interface/), and loaded by an [ASEC::User::Provider::Interface](/Security/User/Provider/Interface/)
* Tokens, representing the authentication of a user, held by an [ASEC::Authentication::Token::Storage](/Security/Authentication/Token/Storage/)
* Voters, which decide whether a user is granted an attribute, such as a role or a permission on an object, via an [ASEC::Authorization::Checker](/Security/Authorization/Checker/)
* Firewalls, which authenticate the users of requests via authenticators, and check their access, via an [ASEC::Firewall](/Security/Firewall/)

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-security:
    github: athena-framework/security
    version: ~> 0.1.0
```

## Usage

### Users

Regardless of where users come from, e.g. a database or configuration, the type representing them includes [ASEC::User::Interface](/Security/User/Interface/):

```crystal
class User
  include ASEC::User::Interface

  getter email : String
  getter roles : Array(String)

  def initialize(@email : String, @roles : Array(String) = ["ROLE_USER"]); end

  def user_identifier : String
    @email
  end
end
```

Users that log in with a password also include [APH::PasswordAuthenticatedUserInterface](/PasswordHasher/PasswordAuthenticatedUserInterface/), whose password is hashed by the [PasswordHasher](/PasswordHasher/) component.

Users are loaded by an [ASEC::User::Provider::Interface](/Security/User/Provider/Interface/), typically from the database.
The component provides:

* [ASEC::User::Provider::InMemory](/Security/User/Provider/InMemory/) - Provides [ASEC::User::InMemory](/Security/User/InMemory/) users kept in memory, useful for testing or applications with a few fixed users
* [ASEC::User::Provider::Chain](/Security/User/Provider/Chain/) - Delegates to multiple providers in turn

```crystal
provider = ASEC::User::Provider::InMemory.new [
  ASEC::User::InMemory.new("admin", "$2y$13$...", ["ROLE_ADMIN"]),
]

provider.load_user_by_identifier("admin").roles # => ["ROLE_ADMIN"]
```

An [ASEC::User::Checker::Interface](/Security/User/Checker/Interface/) may additionally reject users based on the status of their account, e.g. if it is disabled, by raising an [ASEC::Exception::AccountStatus](/Security/Exception/AccountStatus/).

### Tokens

A token represents the authentication of a user, such as the user itself and its roles.
For example, an [ASEC::Authentication::Token::UsernamePassword](/Security/Authentication/Token/UsernamePassword/) represents a user that authenticated on a firewall.

The token of the current user is held by an [ASEC::Authentication::Token::Storage](/Security/Authentication/Token/Storage/):

```crystal
user = provider.load_user_by_identifier "admin"

token_storage = ASEC::Authentication::Token::Storage.new
token_storage.token = ASEC::Authentication::Token::UsernamePassword.new user, "main", user.roles
```

### Checking Access

Whether the current user is granted an attribute is decided by an [ASEC::Authorization::Checker](/Security/Authorization/Checker/).
An attribute is a string that is either a role, such as `ROLE_ADMIN`, or a permission, such as `EDIT`, optionally on a subject, such as a blog post:

```crystal
access_decision_manager = ASEC::Authorization::AccessDecisionManager.new [
  ASEC::Authorization::Voter::Authenticated.new(ASEC::Authentication::TrustResolver.new),
  ASEC::Authorization::Voter::Role.new,
  PostVoter.new,
] of ASEC::Authorization::Voter

checker = ASEC::Authorization::Checker.new token_storage, access_decision_manager

checker.granted? "ROLE_ADMIN"       # => true
checker.granted? "IS_AUTHENTICATED" # => true
checker.granted? "EDIT", post       # => Depends on PostVoter
```

The checker asks an [ASEC::Authorization::AccessDecisionManager](/Security/Authorization/AccessDecisionManager/) for the decision, which in turn asks each of its voters for their [vote](/Security/Authorization/Voter/Access/).
How their votes turn into a decision depends on its [strategy](/Security/Authorization/Strategy/Interface/):

* [ASEC::Authorization::Strategy::Affirmative](/Security/Authorization/Strategy/Affirmative/) (default) - Grants the access as soon as a voter grants it
* [ASEC::Authorization::Strategy::Consensus](/Security/Authorization/Strategy/Consensus/) - Grants the access if more voters grant it than deny it
* [ASEC::Authorization::Strategy::Unanimous](/Security/Authorization/Strategy/Unanimous/) - Grants the access if no voter denies it
* [ASEC::Authorization::Strategy::Priority](/Security/Authorization/Strategy/Priority/) - Grants or denies the access based on the first voter that does not abstain

An [ASEC::Authorization::AccessDecision](/Security/Authorization/AccessDecision/) may be passed to record the decision, along with the votes and the reasons explaining them:

```crystal
access_decision = ASEC::Authorization::AccessDecision.new

checker.granted? "ROLE_SUPER_ADMIN", access_decision: access_decision # => false
access_decision.message                                                # => "Access Denied. The user doesn't have ROLE_SUPER_ADMIN."
```

### Voters

The component provides voters for common attributes:

* [ASEC::Authorization::Voter::Role](/Security/Authorization/Voter/Role/) - Grants the roles of the user, i.e. the attributes starting with `ROLE_`
* [ASEC::Authorization::Voter::RoleHierarchy](/Security/Authorization/Voter/RoleHierarchy/) - Also grants the roles reachable from them via an [ASEC::Role::Hierarchy](/Security/Role/Hierarchy/)
* [ASEC::Authorization::Voter::Authenticated](/Security/Authorization/Voter/Authenticated/) - Grants `IS_AUTHENTICATED` and `IS_AUTHENTICATED_FULLY` based on how the user authenticated, and `PUBLIC_ACCESS` to everyone

Permissions on objects are decided by custom voters, which include [ASEC::Authorization::Voter::Subject(T)](/Security/Authorization/Voter/Subject/) for the type of object they vote on:

```crystal
class PostVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(Post)

  protected def supports?(attribute : String, subject : Post) : Bool
    attribute.in? "VIEW", "EDIT"
  end

  protected def vote_on_attribute(attribute : String, subject : Post, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    return true if attribute == "VIEW" && subject.published?

    subject.author == token.user
  end
end
```

The voter abstains unless it supports the attribute, otherwise it grants the access if `#vote_on_attribute` returns `true`, and denies it if not.
It is only asked to vote on subjects of the type it handles, including subtypes and, for a module, the types including it.
The subject types are known at compile time, so a voter never has to check the type of the subject itself.

A voter may handle multiple types by including [ASEC::Authorization::Voter::Subject(T)](/Security/Authorization/Voter/Subject/) once per type, with overloads of its methods for each of them.
Voters that vote on attributes alone, whatever the subject, include [ASEC::Authorization::Voter::AttributeOnly](/Security/Authorization/Voter/AttributeOnly/) instead.

### Role Hierarchy

Instead of giving many roles to each user, an [ASEC::Role::Hierarchy](/Security/Role/Hierarchy/) may grant roles to other roles, which an [ASEC::Authorization::Voter::RoleHierarchy](/Security/Authorization/Voter/RoleHierarchy/) takes into account:

```crystal
hierarchy = ASEC::Role::Hierarchy.new({
  "ROLE_ADMIN"       => ["ROLE_USER"],
  "ROLE_SUPER_ADMIN" => ["ROLE_ADMIN"],
  "ROLE_EDITOR_*"    => ["ROLE_USER"],
})

voter = ASEC::Authorization::Voter::RoleHierarchy.new hierarchy
```

A user with `ROLE_SUPER_ADMIN` is then also granted `ROLE_ADMIN` and `ROLE_USER`.
A role may contain wildcards, such as `ROLE_EDITOR_*`, which grants its roles to each role it matches, e.g. `ROLE_EDITOR_BLOG`.

### Authenticating Requests

Requiring `athena-security/http` adds the types authenticating the requests handled by the [HTTPKernel](/HTTPKernel/) component, which must also be installed.

An [ASEC::Authenticator::Interface](/Security/Authenticator/Interface/) authenticates the requests it supports, e.g. via an API token.
It creates an [ASEC::Authenticator::Passport](/Security/Authenticator/Passport/) holding the user being authenticated and its credentials, as badges:

```crystal
class APITokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
  def supports?(request : AHTTP::Request) : Bool?
    request.headers.has_key? "x-api-token"
  end

  def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
    api_token = request.headers["x-api-token"]

    # The API token identifies the user, so there are no other credentials to check.
    ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new(api_token) { |token| User.find_by_api_token token }
    )
  end

  def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
    # Let the request continue.
    nil
  end

  def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
    AHTTP::Response.new exception.message_key, :unauthorized
  end
end
```

The listeners of the [ASEC::Events::CheckPassport](/Security/Events/CheckPassport/) event check the passport before the user is authenticated:

* [ASEC::Listeners::UserProvider](/Security/Listeners/UserProvider/) - Loads the user via a user provider, unless the authenticator loads it itself
* [ASEC::Listeners::CheckCredentials](/Security/Listeners/CheckCredentials/) - Verifies [password](/Security/Authenticator/Passport/Credentials/Password/) and [custom](/Security/Authenticator/Passport/Credentials/Custom/) credentials
* [ASEC::Listeners::UserChecker](/Security/Listeners/UserChecker/) - Checks the account of the user via a user checker
* [ASEC::Listeners::PasswordMigrating](/Security/Listeners/PasswordMigrating/) - Upgrades the hashed password of the user once it is authenticated, if needed

Requests are authenticated by firewalls, each handling the requests matching it, e.g. the ones whose path starts with `/api`.
A firewall:

1. Authenticates the user of the request via its authenticators, if they support the request
2. Checks that the user is granted the attribute required for the request, e.g. `ROLE_ADMIN` for paths starting with `/admin`
3. Turns the security exceptions raised while handling the request into responses, e.g. a `403` response if the user is denied access

A user who must authenticate to access a resource gets a `401` response, unless the firewall has an [ASEC::EntryPoint::Interface](/Security/EntryPoint/Interface/) starting the authentication, e.g. by redirecting to the login page.

Firewalls are configured via the [ASEC::Bundle](/Security/Bundle/), such as within an [Athena Framework](/Framework/) application.
Require `athena-security/bundle` to register it, register the authenticators as services, then configure the firewalls:

```crystal
require "athena"
require "athena-security/bundle"

@[ADI::Register]
class APITokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
  # ...
end

ADI.configure({
  security: {
    password_hashers: {
      User => :auto,
    },
    providers: {
      app_users: {id: "app_user_provider"},
    },
    firewalls: {
      api: {
        pattern:               /^\/api/,
        custom_authenticators: ["api_token_authenticator"],
      },
    },
    access_control: [
      {path: /^\/api\/admin/, role: "ROLE_ADMIN"},
      {path: /^\/api/, role: "IS_AUTHENTICATED"},
    ],
  },
})
```

The bundle also registers the services checking the access of users, such as the [ASEC::Authorization::CheckerInterface](/Security/Authorization/CheckerInterface/), which decide via every service inheriting from [ASEC::Authorization::Voter](/Security/Authorization/Voter/).
See [ASEC::Bundle::Schema](/Security/Bundle/Schema/) for the full set of configuration options, or [ASEC::Firewall](/Security/Firewall/) to set up firewalls without the bundle.

### Exceptions

The message of an [ASEC::Exception::Authentication](/Security/Exception/Authentication/) may contain sensitive information, such as whether a user exists, so it must not be shown to users.
Its `#message_key` is safe to show instead, e.g. `"Username could not be found."`.
An [ASEC::Exception::CustomUserMessageAuthentication](/Security/Exception/CustomUserMessageAuthentication/) allows choosing the message shown to users.
