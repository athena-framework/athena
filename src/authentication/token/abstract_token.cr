# Provides the common implementation of tokens.
#
# The role names of a token are set when it is created, and are not updated when the user is changed, as they describe the authentication rather than the roles the user has.
abstract class Athena::Security::Authentication::Token::AbstractToken
  include Athena::Security::Authentication::Token::Interface

  # :inherit:
  getter user : ASEC::User::Interface? = nil

  # :inherit:
  getter role_names : Array(String)

  # :inherit:
  property attributes : Hash(String, String) = {} of String => String

  def initialize(@role_names : Array(String) = [] of String); end

  # :inherit:
  def user=(@user : ASEC::User::Interface)
  end

  # :inherit:
  def user_identifier : String
    @user.try(&.user_identifier) || ""
  end

  # :inherit:
  def has_attribute?(name : String) : Bool
    @attributes.has_key? name
  end

  # :inherit:
  def attribute(name : String, type : T.class) : T forall T
    type.from_json @attributes.fetch(name) { raise ASEC::Exception::InvalidArgument.new "This token has no '#{name}' attribute." }
  end

  # :inherit:
  def attribute?(name : String, type : T.class) : T? forall T
    @attributes[name]?.try { |value| type.from_json value }
  end

  # :inherit:
  def set_attribute(name : String, value : _) : Nil
    @attributes[name] = value.to_json
  end

  # :inherit:
  def to_s(io : IO) : Nil
    io << self.class.name.split("::").last << "(user=\"" << self.user_identifier << "\", roles=\"" << @role_names.join(", ") << "\")"
  end
end
