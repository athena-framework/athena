# An `ART::View` represents an `ART::Response`, but in a format agnostic way.
#
# See the [negotiation](/components/negotiation) component for more information.
class Athena::Routing::View(T)
  # The response data.
  property data : T

  # The `HTTP::Status` of the underlying `#response`.
  property status : HTTP::Status?

  # The format the view should be rendered in.
  property format : String? = nil

  # The parameters that should be used when constructing the redirect `#route` URL.
  property route_params : Hash(String, String)? = nil

  property context : ART::View::Context { ART::View::Context.new }

  # Returns the `URL` that the current request should be redirected to.
  #
  # See the [Location](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location) header documentation.
  getter location : String? = nil

  # Returns the name of the route the current request should be redirected to.
  #
  # See the [URL Generation](/getting_started/#url-generation) documentation.
  getter route : String? = nil

  # The wrapped `ART::Response` instance.
  property response : ART::Response do
    response = ART::Response.new

    if status = @status
      response.status = status
    end

    response
  end

  # Creates a view instance that'll redirect to the provided *url*. See `#location`.
  #
  # Optionally allows setting the underlying *status* and/or *headers*.
  def self.create_redirect(
    url : String,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ART::View(Nil).new status: status, headers: headers
    view.location = url

    view
  end

  # Creates a view instance that'll redirect to the provided *route*. See `#route`.
  #
  # Optionally allows setting the underlying route *params*, *status*, and/or *headers*.
  def self.create_route_redirect(
    route : String,
    params : Hash(String, _)? = nil,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ART::View(Nil).new status: status, headers: headers
    view.route = route
    view.route_params = params.try &.transform_values &.to_s

    view
  end

  def initialize(@data : T? = nil, @status : HTTP::Status? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    self.headers = headers unless headers.empty?
  end

  # Returns the headers of the underlying `#response`.
  def headers : HTTP::Headers
    self.response.headers
  end

  # Sets the redirect `#location`.
  def location=(@location : String) : Nil
    @route = nil
  end

  # Returns the type of the data represented by `self`.
  def return_type : T.class
    T
  end

  # Sets the redirect `#route`.
  def route=(@route : String) : Nil
    @location = nil
  end

  # Adds the provided header *name* and *value* to the underlying `#response`.
  def set_header(name : String, value : String) : Nil
    self.response.headers[name] = value
  end

  # :ditto:
  def set_header(name : String, value : _) : Nil
    self.set_header name, value.to_s
  end

  # Sets the *headers* that should be returned as part of the underlying `#response`.
  def headers=(headers : HTTP::Headers) : Nil
    self.response.headers.clear
    self.response.headers.merge! headers
  end
end
