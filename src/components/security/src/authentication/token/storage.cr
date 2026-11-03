# Holds the token of the current user, optionally loading it lazily via an `#initializer=`.
class Athena::Security::Authentication::Token::Storage
  include Athena::Security::Authentication::Token::Storage::Interface
  include Athena::Contracts::Service::Resettable

  @token : ASEC::Authentication::Token::Interface? = nil
  @initializer : Proc(Nil)? = nil

  # :inherit:
  #
  # Calls the initializer first, if one was set.
  def token : ASEC::Authentication::Token::Interface?
    if initializer = @initializer
      @initializer = nil
      initializer.call
    end

    @token
  end

  # :inherit:
  #
  # Calls the initializer first if a *token* is set, so that it cannot override the *token* later.
  def token=(token : ASEC::Authentication::Token::Interface?)
    self.token unless token.nil?

    @initializer = nil
    @token = token
  end

  # Sets the *initializer* called the next time the token is accessed, which typically sets the token, e.g. after loading it from the session.
  def initializer=(@initializer : Proc(Nil)?)
  end

  # Removes the token.
  def reset : Nil
    self.token = nil
  end
end
