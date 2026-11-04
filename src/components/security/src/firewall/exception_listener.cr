# Converts the security exceptions raised while handling the requests of a firewall into responses:
#
# * An `ASEC::Exception::Authentication` starts the authentication via the entry point of the firewall, e.g. by redirecting to the login page, or results in a `401` response if it has none
# * An `ASEC::Exception::AccessDenied` results in a `403` response if the user is fully authenticated, otherwise it starts the authentication like an `ASEC::Exception::InsufficientAuthentication`
#
# Security exceptions are also handled if they caused the raised exception.
class Athena::Security::Firewall::ExceptionListener
  # Creates a listener for the firewall with the provided *firewall_name*, starting the authentication via the provided *authentication_entry_point*, if any.
  #
  # The *authentication_trust_resolver* determines whether the user of the token held by the provided *token_storage* is fully authenticated.
  def initialize(
    @token_storage : ASEC::Authentication::Token::Storage::Interface,
    @authentication_trust_resolver : ASEC::Authentication::TrustResolverInterface,
    @firewall_name : String,
    @authentication_entry_point : ASEC::EntryPoint::Interface? = nil,
  ); end

  # Handles the security exception of the provided *event*, if any.
  def on_exception(event : AHK::Events::Exception) : Nil
    exception = event.exception

    loop do
      case exception
      when ASEC::Exception::Authentication
        return self.handle_authentication_exception event, exception
      when ASEC::Exception::AccessDenied
        return self.handle_access_denied_exception event, exception
      end

      break unless exception = exception.cause
    end
  end

  private def handle_authentication_exception(event : AHK::Events::Exception, exception : ASEC::Exception::Authentication) : Nil
    Log.info(exception: exception) { "An 'ASEC::Exception::Authentication' was raised; redirecting to authentication entry point." }

    begin
      event.response = self.start_authentication event.request, exception
    rescue ex : ::Exception
      event.exception = ex
    end
  end

  private def handle_access_denied_exception(event : AHK::Events::Exception, exception : ASEC::Exception::AccessDenied) : Nil
    token = @token_storage.token

    unless @authentication_trust_resolver.full_fledged? token
      Log.debug(exception: exception) { "Access denied, the user is not fully authenticated; redirecting to authentication entry point." }

      begin
        insufficient_authentication_exception = ASEC::Exception::InsufficientAuthentication.new "Full authentication is required to access this resource.", exception
        insufficient_authentication_exception.token = token

        # The exception is kept, as the status of the response would otherwise be replaced with the one of an `AHK::Exception::HTTPException`.
        event.response = self.start_authentication event.request, insufficient_authentication_exception
      rescue ex : ::Exception
        event.exception = ex
      end

      return
    end

    Log.debug(exception: exception) { "Access denied, the user is neither anonymous, nor remember-me." }

    event.exception = AHK::Exception::Forbidden.new exception.message || "Access Denied.", exception
  end

  private def start_authentication(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response
    unless entry_point = @authentication_entry_point
      self.raise_unauthorized_exception exception
    end

    Log.debug &.emit "Calling Authentication entry point.", entry_point: entry_point.class.name

    if exception.is_a? ASEC::Exception::AccountStatus
      # Removes the token to prevent infinite redirect loops.
      @token_storage.token = nil

      Log.info(exception: exception) { "The security token was removed due to an 'ASEC::Exception::AccountStatus'." }
    end

    entry_point.start request, exception
  end

  private def raise_unauthorized_exception(exception : ASEC::Exception::Authentication) : NoReturn
    Log.notice { "No Authentication entry point configured, returning a 401 HTTP response. Configure 'entry_point' on the firewall '#{@firewall_name}' if you want to modify the response." }

    raise AHK::Exception::HTTPException.new :unauthorized, exception.message || "", exception
  end
end
