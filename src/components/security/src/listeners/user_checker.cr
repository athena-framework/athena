# Checks the account of users being authenticated via the user checker of a firewall, both before and after their credentials are checked.
class Athena::Security::Listeners::UserChecker
  def initialize(@user_checker : ASEC::User::Checker::Interface); end

  @[AEDA::AsEventListener(priority: 256)]
  def pre_check_credentials(event : ASEC::Events::CheckPassport) : Nil
    @user_checker.check_pre_auth event.passport.user
  end

  @[AEDA::AsEventListener(priority: 256)]
  def post_check_credentials(event : ASEC::Events::AuthenticationSuccess) : Nil
    token = event.authentication_token

    return unless user = token.user

    @user_checker.check_post_auth user, token
  end
end
