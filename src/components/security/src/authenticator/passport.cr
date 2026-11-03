# Holds what must be checked about an authentication before its user is authenticated, as badges.
#
# An `ASEC::Authenticator::Interface` creates a passport from the request, with the user being authenticated and its credentials.
# The listeners of the `ASEC::Events::CheckPassport` event then check it, e.g. by verifying the password, resolving its badges.
# The authentication fails if any of its badges is not resolved once it was checked.
#
# ```
# ASEC::Authenticator::Passport.new(
#   ASEC::Authenticator::Passport::Badge::User.new(email),
#   ASEC::Authenticator::Passport::Credentials::Password.new(password),
# )
# ```
#
# Use an `ASEC::Authenticator::Passport::SelfValidating` if there are no credentials to check, e.g. if the authenticator verified them itself.
class Athena::Security::Authenticator::Passport
  @user : ASEC::User::Interface? = nil
  @badges = Hash(String, ASEC::Authenticator::Passport::Badge::Interface).new

  # Creates a passport for the user of the provided *user_badge*, whose *credentials* must be checked, with the provided additional *badges*.
  def initialize(
    user_badge : ASEC::Authenticator::Passport::Badge::User,
    credentials : ASEC::Authenticator::Passport::Credentials::Interface,
    badges : Enumerable(ASEC::Authenticator::Passport::Badge::Interface) = [] of ASEC::Authenticator::Passport::Badge::Interface,
  )
    self.add_badge user_badge
    self.add_badge credentials

    badges.each do |badge|
      self.add_badge badge
    end
  end

  # Returns the user being authenticated, loaded by the `ASEC::Authenticator::Passport::Badge::User` of this passport.
  #
  # Raises an `ASEC::Exception::Logic` if this passport has no user badge.
  def user : ASEC::User::Interface
    @user ||= begin
      user_badge = self.badge(ASEC::Authenticator::Passport::Badge::User) || raise ASEC::Exception::Logic.new "Cannot get the Security user, no username or 'ASEC::Authenticator::Passport::Badge::User' configured for this passport."

      user_badge.user
    end
  end

  # Adds the provided *badge* to this passport, replacing the badge of the same type, if any.
  #
  # The *badge* may be added as another *badge_class*, e.g. to replace a built-in badge with a subclass of it.
  def add_badge(badge : ASEC::Authenticator::Passport::Badge::Interface, badge_class : ASEC::Authenticator::Passport::Badge::Interface.class = badge.class) : self
    @badges[badge_class.name] = badge

    self
  end

  # Returns `true` if this passport has a badge of the provided *badge_class*, otherwise `false`.
  def has_badge?(badge_class : ASEC::Authenticator::Passport::Badge::Interface.class) : Bool
    @badges.has_key? badge_class.name
  end

  # Returns the badge of the provided *badge_class*, or `nil` if this passport has none.
  def badge(badge_class : T.class) : T? forall T
    @badges[badge_class.name]?.as? T
  end

  # Returns the badges of this passport.
  def badges : Array(ASEC::Authenticator::Passport::Badge::Interface)
    @badges.values
  end
end
