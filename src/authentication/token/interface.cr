# Represents the authentication of a user, such as the user itself, its roles, and the firewall it authenticated on.
#
# Tokens may hold attributes, e.g. the scopes of an access token.
# Each value is stored as JSON, so any type that can be serialized via `#to_json` and deserialized via `.from_json` can be stored.
module Athena::Security::Authentication::Token::Interface
  # Returns the identifier of the user, e.g. its username or email address, or an empty string if there is no user.
  abstract def user_identifier : String

  # Returns the roles granted to the user by this token.
  abstract def role_names : Array(String)

  # Returns the authenticated user, if any.
  abstract def user : ASEC::User::Interface?

  # Sets the authenticated user.
  abstract def user=(user : ASEC::User::Interface)

  # Returns the attributes of this token, with their values serialized as JSON.
  abstract def attributes : Hash(String, String)

  # Replaces the attributes of this token with the provided *attributes*, whose values are serialized as JSON.
  abstract def attributes=(attributes : Hash(String, String))

  # Returns `true` if this token has an attribute with the provided *name*, otherwise `false`.
  abstract def has_attribute?(name : String) : Bool

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*.
  #
  # Raises an `ASEC::Exception::InvalidArgument` if this token has no attribute with that name.
  abstract def attribute(name : String, type : T.class) forall T

  # Returns the value of the attribute with the provided *name*, deserialized as the provided *type*, or `nil` if this token has no attribute with that name.
  abstract def attribute?(name : String, type : T.class) forall T

  # Sets the attribute with the provided *name* to the provided *value*.
  abstract def set_attribute(name : String, value : _) : Nil

  # Writes a representation of this token to the provided *io*, for debugging purposes.
  abstract def to_s(io : IO) : Nil
end
