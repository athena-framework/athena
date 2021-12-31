# Represents data from a request in an agnostic manner, primarily used to augment URL matching and generation with additional context.
class Athena::Routing::RequestContext
  # Represents the path of the URL _before_ `#path`.
  # E.g. a path that should be prefixed to all other `#path`s.
  getter base_url : String

  getter method : String
  getter path : String
  getter host : String
  getter scheme : String
  getter http_port : Int32
  getter https_port : Int32

  # Returns the query string of the current request.
  getter query_string : String

  # Returns the global parameters that should be used as part of the URL generation logic.
  getter parameters : Hash(String, String?) = Hash(String, String?).new

  # Creates a new instance of self from the provided *uri*.
  # The *host*, *scheme*, *http_port*, and *https_port* optionally act as fallbacks if they are not contained within the *uri*.
  def self.from_uri(uri : String, host : String = "localhost", scheme : String = "http", http_port : Int32 = 80, https_port : Int32 = 443) : self
    self.from_uri URI.parse(uri), host, scheme, http_port, https_port
  end

  # :ditto:
  def self.from_uri(uri : URI, host : String = "localhost", scheme : String = "http", http_port : Int32 = 80, https_port : Int32 = 443) : self
    scheme = uri.scheme || scheme

    if port = uri.port
      if "http" == scheme
        http_port = port
      elsif "https" == scheme
        https_port = port
      end
    end

    new(
      uri.path,
      "GET",
      uri.hostname || host,
      scheme,
      http_port,
      https_port
    )
  end

  def initialize(
    @base_url : String = "",
    @method : String = "GET",
    @host : String = "localhost",
    @scheme : String = "http",
    @http_port : Int32 = 80,
    @https_port : Int32 = 443,
    @path : String = "/",
    @query_string : String = ""
  )
    self.method = @method
    self.host = @host
    self.scheme = @scheme
  end

  # Updates the properties within `self` based on the provided *request*.
  def apply(request : ART::Request) : self
    self.method = request.method
    self.host = request.hostname || "localhost"
    self.query_string = request.query || ""

    # TODO: Support this once it's exposed.
    # self.scheme = request.scheme

    self
  end

  def base_url=(@base_url : String) : self
    self
  end

  def path=(@path : String) : self
    self
  end

  def method=(method : String) : self
    @method = method.upcase

    self
  end

  def host=(host : String) : self
    @host = host.downcase

    self
  end

  def scheme=(scheme : String) : self
    @scheme = scheme.downcase

    self
  end

  def query_string=(query_string : String?) : self
    @query_string = query_string.to_s

    self
  end

  def set_parameter(name : String, value : String?) : self
    @parameters[name] = value

    self
  end

  def has_parameter?(name : String) : Bool
    @parameters.has_key name
  end
end
