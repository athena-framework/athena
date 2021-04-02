# Represents custom logic that should be applied for a specific format in order to render an `ART::View` into an `ART::Response`
# that is not handled by default by Athena.  E.g. `HTML`.
#
# ```
# Register our handler as a service.
# @[ADI::Register]
# class HTMLFormatHandler
#   # Implement the interface.
#   include Athena::Routing::View::FormatHandlerInterface
#
#   # Turn the provided data into a response that can be returned to the client.
#   def call(view_handler : ART::View::ViewHandlerInterface, view : ART::ViewBase, request : ART::Request, format : String) : ART::Response
#     ART::Response.new "<h1>#{view.data}</h1>", headers: HTTP::Headers{"content-type" => "text/html"}
#   end
#
#   # Specify that `self` handles the `HTML` format.
#   def format : String
#     "html"
#   end
# end
# ```
#
# The implementation for `HTML` for example could use `.to_s` as depicted here, or utilize a templating engine, possibly taking advantage
# of [custom annotations](/components/config/#custom-annotations) to allow specifying the related template name.
module Athena::Routing::View::FormatHandlerInterface
  TAG = "athena.format_handler"

  # Apply `TAG` to all `ART::View::FormatHandlerInterface` instances automatically.
  ADI.auto_configure Athena::Routing::View::FormatHandlerInterface, {tags: [Athena::Routing::View::FormatHandlerInterface::TAG]}

  # Responsible for returning an `ART::Response` for the provided *view* and *request* in the provided *format*.
  #
  # The `ART::View::ViewHandlerInterface` is also provided to ease response creation.
  abstract def call(view_handler : ART::View::ViewHandlerInterface, view : ART::View, request : ART::Request, format : String) : ART::Response

  # Returns the format that `self` handles.
  abstract def format : String
end
