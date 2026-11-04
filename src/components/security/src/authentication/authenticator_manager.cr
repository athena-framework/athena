# Authenticates the requests of a firewall via its authenticators.
#
# Each authenticator supporting the request creates an `ASEC::Authenticator::Passport`, which is checked by the listeners of the `ASEC::Events::CheckPassport` event.
# Once every badge of the passport is resolved, the authenticator creates the token of the user, which is set on the token storage.
# The first authenticator returning a response, e.g. a redirect after logging in, ends the authentication.
#
# The events are dispatched via the provided event dispatcher, which is typically specific to the firewall, so that its listeners only handle its authentications, e.g. `ASEC::Listeners::UserProvider` with its user provider.
#
# ```
# dispatcher = AED::EventDispatcher.new
# dispatcher.listener ASEC::Listeners::UserProvider.new user_provider
# dispatcher.listener ASEC::Listeners::CheckCredentials.new password_hasher_factory
#
# authenticator_manager = ASEC::Authentication::AuthenticatorManager.new(
#   [APITokenAuthenticator.new] of ASEC::Authenticator::Interface,
#   token_storage,
#   dispatcher,
#   "main",
# )
# ```
class Athena::Security::Authentication::AuthenticatorManager
  # Creates a manager authenticating requests via the provided *authenticators* on the firewall with the provided *firewall_name*.
  #
  # The token of the authenticated user is set on the provided *token_storage*, and the events are dispatched via the provided *event_dispatcher*.
  # The *expose_security_errors* determine which authentication errors are passed to the authenticators, which may show them to users.
  def initialize(
    @authenticators : Array(ASEC::Authenticator::Interface),
    @token_storage : ASEC::Authentication::Token::Storage::Interface,
    @event_dispatcher : AED::EventDispatcherInterface,
    @firewall_name : String,
    @expose_security_errors : ASEC::Authentication::ExposeSecurityLevel = :none,
  ); end

  # Returns `true` if any authenticator supports the provided *request*, `false` if none does, or `nil` if they all support authenticating it lazily.
  #
  # The authenticators supporting the *request* are stored on it for `#authenticate_request`.
  def supports?(request : AHTTP::Request) : Bool?
    authenticators = [] of ASEC::Authenticator::Interface
    skipped_authenticators = [] of ASEC::Authenticator::Interface
    lazy = true

    @authenticators.each do |authenticator|
      supports = authenticator.supports? request

      if supports == false
        skipped_authenticators << authenticator
      else
        authenticators << authenticator
        lazy &&= supports.nil?
      end
    end

    Log.debug &.emit(
      "Checked for authenticator support.",
      firewall_name: @firewall_name,
      supporting_authenticators: authenticators.map(&.class.name),
      skipped_authenticators: skipped_authenticators.map(&.class.name),
    )

    request.attributes.set "_security_authenticators", authenticators

    return false if authenticators.empty?

    lazy ? nil : true
  end

  # Authenticates the provided *request* via the authenticators supporting it, as determined by `#supports?`.
  #
  # Returns the response to send, or `nil` to let the request continue.
  def authenticate_request(request : AHTTP::Request) : AHTTP::Response?
    authenticators = request.attributes.get? "_security_authenticators", Array(ASEC::Authenticator::Interface)
    request.attributes.remove "_security_authenticators"

    return if authenticators.nil? || authenticators.empty?

    self.execute_authenticators authenticators, request
  end

  private def execute_authenticators(authenticators : Array(ASEC::Authenticator::Interface), request : AHTTP::Request) : AHTTP::Response?
    authenticators.each do |authenticator|
      # Checks the support again, as `#supports?` may have been called before the token storage was initialized, while authenticating may happen lazily after it.
      if authenticator.supports?(request) == false
        Log.debug &.emit "Skipping the authenticator as it did not support the request.", authenticator: authenticator.class.name

        next
      end

      if response = self.execute_authenticator authenticator, request
        Log.debug &.emit "The authenticator set the response. Any later authenticator will not be called.", authenticator: authenticator.class.name

        return response
      end
    end

    nil
  end

  private def execute_authenticator(authenticator : ASEC::Authenticator::Interface, request : AHTTP::Request) : AHTTP::Response?
    passport = nil
    previous_token = @token_storage.token

    begin
      passport = authenticator.authenticate request

      @event_dispatcher.dispatch ASEC::Events::CheckPassport.new authenticator, passport

      passport.badges.each do |badge|
        unless badge.resolved?
          raise ASEC::Exception::BadCredentials.new "Authentication failed: Security badge '#{badge.class}' is not resolved, did you forget to register the correct listeners?"
        end
      end

      authenticated_token = authenticator.create_token passport, @firewall_name

      @event_dispatcher.dispatch token_created_event = ASEC::Events::AuthenticationTokenCreated.new(authenticated_token, passport)
      authenticated_token = token_created_event.authenticated_token

      @event_dispatcher.dispatch ASEC::Events::AuthenticationSuccess.new authenticated_token

      Log.info &.emit "Authenticator successful!", token: authenticated_token.to_s, authenticator: authenticator.class.name
    rescue ex : ASEC::Exception::Authentication
      return self.handle_authentication_failure ex, request, authenticator, passport
    end

    # Handled outside of the `begin` block, so that an exception raised by the success handling is not treated as an authentication failure.
    response = self.handle_authentication_success authenticated_token, passport, request, authenticator, previous_token

    if response.nil?
      Log.debug &.emit "Authenticator set no success response: request continues.", authenticator: authenticator.class.name
    end

    response
  end

  private def handle_authentication_success(
    authenticated_token : ASEC::Authentication::Token::Interface,
    passport : ASEC::Authenticator::Passport,
    request : AHTTP::Request,
    authenticator : ASEC::Authenticator::Interface,
    previous_token : ASEC::Authentication::Token::Interface?,
  ) : AHTTP::Response?
    @token_storage.token = authenticated_token

    response = authenticator.on_authentication_success request, authenticated_token, @firewall_name

    @event_dispatcher.dispatch login_success_event = ASEC::Events::LoginSuccess.new(
      authenticator,
      passport,
      authenticated_token,
      request,
      response,
      @firewall_name,
      previous_token
    )

    login_success_event.response
  end

  private def handle_authentication_failure(
    exception : ASEC::Exception::Authentication,
    request : AHTTP::Request,
    authenticator : ASEC::Authenticator::Interface,
    passport : ASEC::Authenticator::Passport?,
  ) : AHTTP::Response?
    Log.info(exception: exception, &.emit "Authenticator failed.", authenticator: authenticator.class.name)

    # Hides whether the user exists, e.g. a user not found or an invalid account status, so that users cannot be enumerated by comparing responses.
    if self.sensitive_exception? exception
      exception = ASEC::Exception::BadCredentials.new "Bad credentials.", exception
    end

    response = authenticator.on_authentication_failure request, exception

    unless response.nil?
      Log.debug &.emit "The authenticator set the failure response.", authenticator: authenticator.class.name
    end

    @event_dispatcher.dispatch login_failure_event = ASEC::Events::LoginFailure.new(
      exception,
      authenticator,
      request,
      response,
      @firewall_name,
      passport
    )

    # A `nil` response lets the request continue.
    login_failure_event.response
  end

  private def sensitive_exception?(exception : ASEC::Exception::Authentication) : Bool
    if !@expose_security_errors.all? && exception.is_a?(ASEC::Exception::UserNotFound)
      return true
    end

    if @expose_security_errors.none? && exception.is_a?(ASEC::Exception::AccountStatus) && !exception.is_a?(ASEC::Exception::CustomUserMessageAccountStatus)
      return true
    end

    false
  end
end
