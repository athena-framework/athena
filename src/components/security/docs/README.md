The `Athena::Security` component provides the building blocks to authenticate users and decide what they are allowed to do:

* Users, represented by an [ASEC::User::Interface](/Security/User/Interface/), and loaded by an [ASEC::User::Provider::Interface](/Security/User/Provider/Interface/)
* Tokens, representing the authentication of a user, held by an [ASEC::Authentication::Token::Storage](/Security/Authentication/Token/Storage/)
* Voters, which decide whether a user is granted an attribute, such as a role or a permission on an object, via an [ASEC::Authorization::Checker](/Security/Authorization/Checker/)

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

### Exceptions

The message of an [ASEC::Exception::Authentication](/Security/Exception/Authentication/) may contain sensitive information, such as whether a user exists, so it must not be shown to users.
Its `#message_key` is safe to show instead, e.g. `"Username could not be found."`.
An [ASEC::Exception::CustomUserMessageAuthentication](/Security/Exception/CustomUserMessageAuthentication/) allows choosing the message shown to users.
