require "./response"

# Represents an HTTP response that does a redirect.
#
# Can be used as an easier way to handle redirects as well as providing type saftey that a route should redirect.
#
# ```
# class RedirectController < ART::Controller
#   @[ART::Get(path: "/go_to_crystal")]
#   def redirect_to_crystal : ART::RedirectResponse
#     ART::RedirectResponse.new "https://crystal-lang.org"
#   end
# end
# ```
class Athena::Routing::RedirectResponse < Athena::Routing::Response
  # The url that the request will be redirected to.
  getter url : String

  # Creates a response that should redirect to the provided *url* with the provided *status*, defaults to 302.
  #
  # An ArgumentError is raised if *url* is blank, or if *status* is not a valid redirection status code.
  def initialize(@url : String, status : HTTP::Status | Int32 = HTTP::Status::FOUND, headers : HTTP::Headers = HTTP::Headers.new)
    raise ArgumentError.new "Cannot redirect to an empty URL." if @url.blank?

    headers["location"] = @url

    super "", status, headers

    raise ArgumentError.new "#{@status.value} is not an HTTP redirect status code." unless @status.redirection?
  end
end
