# Rejects disabled `ASEC::User::InMemory` users, ignoring any other user.
class Athena::Security::User::Checker::InMemory
  include Athena::Security::User::Checker::Interface

  # :inherit:
  def check_pre_auth(user : ASEC::User::Interface) : Nil
    return unless user.is_a? ASEC::User::InMemory
    return if user.enabled?

    raise ASEC::Exception::Disabled.new "User account is disabled.", user: user
  end

  # :inherit:
  def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil
  end
end
