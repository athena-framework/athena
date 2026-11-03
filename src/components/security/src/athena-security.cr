require "json"

require "athena-contracts/service"
require "athena-password_hasher"

require "./user/interface"
require "./user/equatable_interface"
require "./user/password_upgrader_interface"
require "./user/in_memory"
require "./user/provider/interface"
require "./user/provider/*"
require "./user/checker/interface"
require "./user/checker/*"

require "./authentication/token/interface"
require "./authentication/token/abstract_token"
require "./authentication/token/null"
require "./authentication/token/username_password"
require "./authentication/token/storage/interface"
require "./authentication/token/storage"
require "./authentication/trust_resolver_interface"
require "./authentication/trust_resolver"

require "./authorization/voter"
require "./authorization/voter/attribute_only"
require "./authorization/voter/subject"
require "./authorization/voter/vote"
require "./authorization/voter/authenticated"
require "./authorization/voter/role"
require "./authorization/voter/role_hierarchy"
require "./authorization/strategy/interface"
require "./authorization/strategy/*"
require "./authorization/access_decision"
require "./authorization/access_decision_manager"
require "./authorization/checker_interface"
require "./authorization/checker"

require "./role/hierarchy_interface"
require "./role/hierarchy"

require "./exception/authentication"
require "./exception/account_status"
require "./exception/authentication_service"
require "./exception/*"

# Convenience alias to make referencing `Athena::Security` types easier.
alias ASEC = Athena::Security

# Provides authentication and authorization utilities.
module Athena::Security
  VERSION = "0.1.0"

  # Types related to authenticating users, such as the tokens representing their authentication.
  module Authentication; end

  # Types related to deciding whether users are granted access, such as voters.
  module Authorization; end

  # Both acts as a namespace for exceptions related to the `Athena::Security` component, as well as a way to check for exceptions from the component.
  module Exception; end

  # Types related to roles.
  module Role; end

  # Types related to users, such as the providers loading them.
  module User; end
end
