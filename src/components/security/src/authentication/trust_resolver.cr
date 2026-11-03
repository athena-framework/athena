# Resolves how much a token can be trusted based on its user.
class Athena::Security::Authentication::TrustResolver
  include Athena::Security::Authentication::TrustResolverInterface

  # :inherit:
  def authenticated?(token : ASEC::Authentication::Token::Interface?) : Bool
    !token.nil? && !token.user.nil?
  end

  # :inherit:
  #
  # TODO: Every authenticated user is fully authenticated, until "remember me" is supported.
  def full_fledged?(token : ASEC::Authentication::Token::Interface?) : Bool
    self.authenticated? token
  end
end
