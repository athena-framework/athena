# Upgrades the hashed password of users once they are authenticated, if their password hasher needs to rehash it, e.g. because its cost was increased.
#
# Only applies to passports with an `ASEC::Authenticator::Passport::Badge::PasswordUpgrade` badge.
# The new hashed password is persisted via the password upgrader of the badge, or else via the user provider of the `ASEC::Authenticator::Passport::Badge::User`, if it is an `ASEC::User::PasswordUpgraderInterface`.
class Athena::Security::Listeners::PasswordMigrating
  def initialize(@hasher_factory : APH::FactoryInterface); end

  @[AEDA::AsEventListener]
  def on_login_success(event : ASEC::Events::LoginSuccess) : Nil
    passport = event.passport

    return unless badge = passport.badge ASEC::Authenticator::Passport::Badge::PasswordUpgrade

    plaintext_password = badge.erase_plaintext_password

    return if plaintext_password.empty?

    user = passport.user

    return unless user.is_a? APH::PasswordAuthenticatedUserInterface
    return unless hashed_password = user.password

    password_hasher = @hasher_factory.password_hasher user

    return unless password_hasher.needs_rehash? hashed_password

    unless password_upgrader = badge.password_upgrader
      password_upgrader = passport.badge(ASEC::Authenticator::Passport::Badge::User).try &.user_provider.as?(ASEC::User::PasswordUpgraderInterface)

      return unless password_upgrader
    end

    password_upgrader.upgrade_password user, password_hasher.hash(plaintext_password)
  end
end
