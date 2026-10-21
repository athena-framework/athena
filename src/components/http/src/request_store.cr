# Stores a `AHTTP::Request` object.
class Athena::HTTP::RequestStore
  property! request : AHTTP::Request

  # Returns the session of the stored request.
  #
  # Raises an `AHTTP::Exception::SessionNotFound` if there is no request, or it does not have a session.
  def session : AHTTP::Session
    if (request = @request) && request.has_session?
      return request.session
    end

    raise AHTTP::Exception::SessionNotFound.new "There is currently no session available."
  end

  # Resets the store, removing the reference to the request.
  #
  # Used internally after the response has been returned.
  protected def reset : Nil
    @request = nil
  end
end
