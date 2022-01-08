require "./response"

# Represents an HTTP response that does a redirect.
#
# Can be used as an easier way to handle redirects as well as providing type safety that a route should redirect.
#
# ```
# require "athena"
#
# class RedirectController < ATH::Controller
#   @[ARTA::Get(path: "/go_to_crystal")]
#   def redirect_to_crystal : ATH::RedirectResponse
#     ATH::RedirectResponse.new "https://crystal-lang.org"
#   end
# end
#
# ATH.run
#
# # GET /go_to_crystal # => (redirected to https://crystal-lang.org)
# ```
class Athena::Framework::RedirectResponse < Athena::Framework::Response
  # The url that the request will be redirected to.
  getter url : String

  # Creates a response that should redirect to the provided *url* with the provided *status*, defaults to 302.
  #
  # An ArgumentError is raised if *url* is blank, or if *status* is not a valid redirection status code.
  def initialize(url : String | Path, status : HTTP::Status | Int32 = HTTP::Status::FOUND, headers : HTTP::Headers | ATH::Response::Headers = ATH::Response::Headers.new)
    @url = url.to_s

    raise ArgumentError.new "Cannot redirect to an empty URL." if @url.blank?

    headers["location"] = @url

    super "", status, headers

    raise ArgumentError.new "'#{@status.value}' is not an HTTP redirect status code." unless @status.redirection?
  end
end
