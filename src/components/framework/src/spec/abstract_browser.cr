# Simulates a browser to make requests to some destination.
#
# NOTE: Currently just acts as a client to make `HTTP` requests. This type exists to allow for introduction of other functionality in the future.
abstract class Athena::Framework::Spec::AbstractBrowser
  @request : ATH::Request?
  @response : HTTP::Server::Response?

  # :nodoc:
  #
  # Makes a *request* and returns the response.
  abstract def do_request(request : ATH::Request) : HTTP::Server::Response

  def request : ATH::Request
    if request = @request
      return request
    end

    raise RuntimeError.new "The '#request' method must be called before a request is available."
  end

  def response : HTTP::Server::Response
    if response = @response
      return response
    end

    raise RuntimeError.new "The '#request' method must be called before a response is available."
  end

  # Makes an HTTP request with the provided *method*, at the provided *path*, with the provided *body* and/or *headers* and returns the resulting response.
  def request(
    method : String,
    path : String,
    headers : HTTP::Headers,
    body : String | Bytes | IO | Nil
  ) : HTTP::Server::Response
    # At the moment this just calls into `do_request`.
    # Kept this as way allow for future expansion.

    self.request ATH::Request.new method, path, headers, body
  end

  # Makes an HTTP request with the provided *request*, returning the resulting response.
  def request(request : ATH::Request | HTTP::Request) : HTTP::Server::Response
    @request = ATH::Request.new request

    @response = self.do_request self.request
  end
end
