# Checks the `ASEC::Authenticator::Passport::Credentials::Password` and `ASEC::Authenticator::Passport::Credentials::Custom` credentials of passports.
#
# Passwords are verified via the password hasher of the user, and add an `ASEC::Authenticator::Passport::Badge::PasswordUpgrade` badge to the passport if it has none, so that `ASEC::Listeners::PasswordMigrating` can upgrade the password.
class Athena::Security::Listeners::CheckCredentials
  def initialize(@hasher_factory : APH::FactoryInterface); end

  @[AEDA::AsEventListener]
  def check_passport(event : ASEC::Events::CheckPassport) : Nil
    passport = event.passport

    if credentials = passport.badge ASEC::Authenticator::Passport::Credentials::Password
      # Uses the password hasher to verify the credentials.
      user = passport.user

      unless user.is_a? APH::PasswordAuthenticatedUserInterface
        raise ASEC::Exception::Logic.new "Class '#{user.class}' must include 'APH::PasswordAuthenticatedUserInterface' for using password-based authentication."
      end

      return if credentials.resolved?

      presented_password = credentials.password

      raise ASEC::Exception::BadCredentials.new "The presented password cannot be empty." if presented_password.empty?

      unless hashed_password = user.password
        raise ASEC::Exception::BadCredentials.new "The presented password is invalid."
      end

      unless @hasher_factory.password_hasher(user).verify hashed_password, presented_password
        raise ASEC::Exception::BadCredentials.new "The presented password is invalid."
      end

      credentials.mark_resolved

      unless passport.has_badge? ASEC::Authenticator::Passport::Badge::PasswordUpgrade
        passport.add_badge ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new presented_password
      end

      return
    end

    if credentials = passport.badge ASEC::Authenticator::Passport::Credentials::Custom
      return if credentials.resolved?

      credentials.execute_custom_checker passport.user
    end
  end
end
