# :nodoc:
class Athena::Framework::Controller::Redirect
  def initialize(
    @http_port : Int32? = nil,
    @https_port : Int32? = nil
  ); end

  # ameba:disable Metrics/CyclomaticComplexity:
  def redirect_url(
    request : ATH::Request,
    path : String,
    permanent : Bool = false,
    scheme : String? = nil,
    http_port : Int32? = nil,
    https_port : Int32? = nil,
    keep_request_method : Bool = false
  ) : ATH::RedirectResponse
    if path.empty?
      raise ATH::Exception::HTTPException.new (permanent ? HTTP::Status::GONE : HTTP::Status::NOT_FOUND), ""
    end

    status = if keep_request_method
               permanent ? HTTP::Status::PERMANENT_REDIRECT : HTTP::Status::TEMPORARY_REDIRECT
             else
               permanent ? HTTP::Status::MOVED_PERMANENTLY : HTTP::Status::FOUND
             end

    uri = URI.parse path

    # If the path has a scheme, assume it is a full URI
    if uri.scheme.presence
      return ATH::RedirectResponse.new path, status
    end

    # TODO: Get the scheme off of the request
    uri.scheme = scheme

    # If the request has query params of its own, be sure to retain both sets of params.
    if request.query.presence
      # Don't use `merge!` here so the query string is correctly refreshed on the uri.
      uri.query_params = uri.query_params.merge request.query_params, replace: false
    end

    if "http" == scheme
      if http_port.nil?
        # TODO: Get the port off the request once we know scheme
        http_port = @http_port
      end

      uri.port = http_port
    elsif "https" == scheme
      if https_port.nil?
        # TODO: Get the port off the request once we know scheme
        https_port = @https_port
      end

      uri.port = https_port
    end

    uri.host = request.host

    ATH::RedirectResponse.new uri.normalize!.to_s, status
  end
end
