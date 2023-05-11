class Athena::Framework::Controller::Redirect
  def redirect_url(
    request : ATH::Request,
    path : String,
    permanent : Bool = false,
    scheme : String? = nil,
    http_port : Int32? = nil,
    https_port : Int32? = nil,
    keep_request_method : Bool = false
  ) : ATH::RedirectResponse
    status = if keep_request_method
               permanent ? HTTP::Status::TEMPORARY_REDIRECT : HTTP::Status::PERMANENT_REDIRECT
             else
               permanent ? HTTP::Status::MOVED_PERMANENTLY : HTTP::Status::FOUND
             end

    # TODO: Handle redirecting to full URLs
    # TODO: Handle customizing scheme/ports

    ATH::RedirectResponse.new path, status
  end
end
