# Simulates a browser to make requests to some destination.
#
# NOTE: Currently just acts as a client to make `HTTP` requests, sending the cookies it received with subsequent requests. This type exists to allow for introduction of other functionality in the future.
abstract class Athena::Framework::Spec::AbstractBrowser
  @request : AHTTP::Request?
  @response : ::HTTP::Server::Response?

  # Returns the `ATH::Spec::CookieJar` storing the cookies received from previous requests, which are sent with subsequent requests.
  getter cookie_jar : ATH::Spec::CookieJar = ATH::Spec::CookieJar.new

  # :nodoc:
  #
  # Makes a *request* and returns the response.
  abstract def do_request(request : AHTTP::Request) : ::HTTP::Server::Response

  def request : AHTTP::Request
    if request = @request
      return request
    end

    raise RuntimeError.new "The '#request' method must be called before a request is available."
  end

  def response : ::HTTP::Server::Response
    if response = @response
      return response
    end

    raise RuntimeError.new "The '#request' method must be called before a response is available."
  end

  # Makes an HTTP request with the provided *method*, at the provided *path*, with the provided *body* and/or *headers* and returns the resulting response.
  def request(
    method : String,
    path : String,
    headers : ::HTTP::Headers,
    body : String | Bytes | IO | Nil,
  ) : ::HTTP::Server::Response
    # At the moment this just calls into `do_request`.
    # Kept this as way allow for future expansion.

    self.request AHTTP::Request.new method, path, headers, body
  end

  # Makes an HTTP request with the provided *request*, returning the resulting response.
  def request(request : AHTTP::Request | ::HTTP::Request) : ::HTTP::Server::Response
    @request = request = AHTTP::Request.new request

    uri = URI.new scheme: request.scheme, host: request.host || "localhost", path: request.path

    unless (jar_values = @cookie_jar.all_values uri).empty?
      # Cookies explicitly provided with the request take precedence over those from the jar.
      cookies = request.cookies
      jar_values.each do |name, value|
        cookies << ::HTTP::Cookie.new(name, value) unless cookies.has_key? name
      end
      cookies.add_request_headers request.headers
    end

    @response = response = self.do_request request

    @cookie_jar.update_from_response response, uri

    response
  end
end
