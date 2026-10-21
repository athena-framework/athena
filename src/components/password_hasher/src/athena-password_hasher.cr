require "base64"
require "crypto/bcrypt"
require "crypto/subtle"
require "digest/sha512"
require "random/secure"

require "./interface"
require "./password_authenticated_user_interface"
require "./password_hasher_aware_interface"
require "./factory_interface"
require "./user_password_hasher_interface"

require "./exception/*"

require "./factory"
require "./migrating"
require "./native"
require "./user_password_hasher"

# The command is only defined when the console component is required, before or after this file.
macro finished
  {% if @top_level.has_constant? "ACON" %}
    require "./commands/*"
  {% end %}
end

# Convenience alias to make referencing `Athena::PasswordHasher` types easier.
alias APH = Athena::PasswordHasher

# Provides secure password hashing and verification utilities.
module Athena::PasswordHasher
  VERSION = "0.1.0"

  # Contains the console commands provided by the component, when the [Console](/Console/) component is installed.
  module Commands; end

  # Both acts as a namespace for exceptions related to the `Athena::PasswordHasher` component, as well as a way to check for exceptions from the component.
  module Exception; end
end
