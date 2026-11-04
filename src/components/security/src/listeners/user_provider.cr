# Sets the user provider of a firewall as the user loader of the `ASEC::Authenticator::Passport::Badge::User` of passports, if the authenticator did not set one.
#
# Runs before the other `ASEC::Events::CheckPassport` listeners, which typically need the user.
class Athena::Security::Listeners::UserProvider
  def initialize(@user_provider : ASEC::User::Provider::Interface); end

  @[AEDA::AsEventListener(priority: 2048)]
  def check_passport(event : ASEC::Events::CheckPassport) : Nil
    return unless user_badge = event.passport.badge ASEC::Authenticator::Passport::Badge::User
    return unless user_badge.user_loader.nil?

    user_badge.user_provider = @user_provider
  end
end
