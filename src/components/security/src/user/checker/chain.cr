# Checks users with each of its checkers in turn.
class Athena::Security::User::Checker::Chain
  include Athena::Security::User::Checker::Interface

  def initialize(@checkers : Array(ASEC::User::Checker::Interface)); end

  # :inherit:
  def check_pre_auth(user : ASEC::User::Interface) : Nil
    @checkers.each &.check_pre_auth(user)
  end

  # :inherit:
  def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil
    @checkers.each &.check_post_auth(user, token)
  end
end
