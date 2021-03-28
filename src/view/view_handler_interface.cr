# Processes an `ART::View` into an `ART::Response` of the proper format.
#
# See the [negotiation](/components/negotiation) component for more information.
module Athena::Routing::View::ViewHandlerInterface
  # The possible types for a view format handler.
  alias HandlerType = ART::View::FormatHandlerInterface | Proc(ART::View::ViewHandlerInterface, ART::ViewBase, HTTP::Request, String, ART::Response)

  # Registers the provided *handler* to handle the provided *format*.
  abstract def register_handler(format : String, handler : ART::View::ViewHandlerInterface::HandlerType) : Nil

  # Determines if `self` can handle the provided *format*.
  #
  # First checks if a custom format handler supports the provided *format*,
  # otherwise falls back on the `ASR::SerializerInterface`.
  abstract def supports?(format : String) : Bool

  # Handles the conversion of the provided *view* into an `ART::Response`.
  #
  # If no *request* is provided, it is fetched from `ART::RequestStore`.
  abstract def handle(view : ART::ViewBase, request : HTTP::Request? = nil) : ART::Response

  # Creates an `ART::Response` based on the provided *view* that'll redirect to the provided *location*.
  #
  # *location* may either be a `URL` or the name of a route.
  abstract def create_redirect_response(view : ART::ViewBase, location : String, format : String) : ART::Response

  # Creates an `ART::Response` based on the provided *view* and *request*.
  abstract def create_response(view : ART::ViewBase, request : HTTP::Request, format : String) : ART::Response
end
