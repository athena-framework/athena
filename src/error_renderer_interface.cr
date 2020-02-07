# An `ART::ErrorRendererInterface` converts an `::Exception` into an `ART::Response`.
#
# By default, exceptions are JSON serialized via `ART::ErrorRenderer`.  However, it can be overridden
# to allow rendering errors differently, such as via HTML.
#
# ```
# @[ADI::Register(name: "error_renderer")]
# # A custom error renderer must redefine the default `ART::ErrorRenderer` by registering a service with the name `"error_renderer"`.
# struct Athena::Routing::CustomErrorRenderer
#   include Athena::Routing::ErrorRendererInterface
#   include ADI::Service
#
#   # :inherit:
#   def render(exception : ::Exception) : ART::Response
#     if exception.is_a? ART::Exceptions::HTTPException
#       status = exception.status
#       headers = exception.headers
#     else
#       status = HTTP::Status::INTERNAL_SERVER_ERROR
#       headers = HTTP::Headers.new
#     end
#
#     body = <<-HTML
#       <html>
#         <head>
#           <title>Uh oh</title>
#         </head>
#         <body>
#           <h1>Uh oh, something went wrong</h1>
#         </body>
#       </html>
#     HTML
#
#     headers["content-type"] = "text/html"
#
#     ART::Response.new body, status, headers
#   end
# end
# ```
module Athena::Routing::ErrorRendererInterface
  # Renders the given *exception* into an `ART::Response`.
  abstract def render(exception : ::Exception) : ART::Response
end
