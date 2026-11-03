# Represents the absence of an authenticated user, e.g. when deciding the access of a guest.
class Athena::Security::Authentication::Token::Null
  include Athena::Security::Authentication::Token::Interface

  # :inherit:
  def user_identifier : String
    ""
  end

  # :inherit:
  def role_names : Array(String)
    [] of String
  end

  # :inherit:
  def user : ASEC::User::Interface?
    nil
  end

  # :inherit:
  #
  # Raises an `ASEC::Exception::Logic`, as a null token has no user.
  def user=(user : ASEC::User::Interface) : NoReturn
    raise ASEC::Exception::Logic.new "Cannot set user on a null token."
  end

  # :inherit:
  def attributes : Hash(String, String)
    {} of String => String
  end

  # :inherit:
  #
  # Raises an `ASEC::Exception::Logic`, as a null token has no attributes.
  def attributes=(attributes : Hash(String, String)) : NoReturn
    raise ASEC::Exception::Logic.new "Cannot set attributes of a null token."
  end

  # :inherit:
  def has_attribute?(name : String) : Bool
    false
  end

  # :inherit:
  def attribute(name : String, type : T.class) : T forall T
    raise ASEC::Exception::InvalidArgument.new "This token has no '#{name}' attribute."
  end

  # :inherit:
  def attribute?(name : String, type : T.class) : T? forall T
    nil
  end

  # :inherit:
  #
  # Raises an `ASEC::Exception::Logic`, as a null token has no attributes.
  def set_attribute(name : String, value : _) : NoReturn
    raise ASEC::Exception::Logic.new "Cannot add attribute to a null token."
  end

  # :inherit:
  def to_s(io : IO) : Nil
  end
end
