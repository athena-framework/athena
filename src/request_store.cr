@[ADI::Register]
# Stores the current `HTTP::Request` object.
#
# Can be injected to access the request from a non controller context.
class Athena::Routing::RequestStore
  @request : HTTP::Request? = nil

  # Resets the store, removing the reference to the request.
  #
  # Used internally after the request has been returned.
  def reset : Nil
    @request = nil
  end

  # Returns the currently executing request.
  #
  # Use `#request?` if it's possible there is no request.
  def request : HTTP::Request
    @request.not_nil!
  end

  # Returns the currently executing request if it exists, otherwise `nil`.
  def request? : HTTP::Request?
    @request
  end

  # Sets the currently executing request.
  def request=(@request : HTTP::Request); end
end
