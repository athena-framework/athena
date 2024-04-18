# An `ATH::ErrorRendererInterface` converts an `::Exception` into an `ATH::Response`.
#
# By default, exceptions are JSON serialized via `ATH::ErrorRenderer`. However, it can be overridden
# to allow rendering errors differently, such as via HTML.
#
# ```
# require "athena"
#
# # Alias this service to be used when the `ATH::ErrorRendererInterface` type is encountered.
# @[ADI::Register]
# @[ADI::AsAlias]
# struct Athena::Framework::CustomErrorRenderer
#   include Athena::Framework::ErrorRendererInterface
#
#   # :inherit:
#   def render(exception : ::Exception) : ATH::Response
#     if exception.is_a? ATH::Exceptions::HTTPException
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
#     ATH::Response.new body, status, headers
#   end
# end
#
# class TestController < ATH::Controller
#   get "/" do
#     raise "some error"
#   end
# end
#
# ATH.run
#
# # GET / # =>   <html><head><title>Uh oh</title></head><body><h1>Uh oh, something went wrong</h1></body></html>
# ```
module Athena::Framework::ErrorRendererInterface
  # Renders the given *exception* into an `ATH::Response`.
  abstract def render(exception : ::Exception) : ATH::Response
end
