# A passport without credentials to check, e.g. because its authenticator already verified an API token.
class Athena::Security::Authenticator::Passport::SelfValidating < Athena::Security::Authenticator::Passport
  # Creates a passport for the user of the provided *user_badge*, with the provided additional *badges*.
  def initialize(
    user_badge : ASEC::Authenticator::Passport::Badge::User,
    badges : Enumerable(ASEC::Authenticator::Passport::Badge::Interface) = [] of ASEC::Authenticator::Passport::Badge::Interface,
  )
    self.add_badge user_badge

    badges.each do |badge|
      self.add_badge badge
    end
  end
end
