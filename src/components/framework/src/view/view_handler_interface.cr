# Processes an `ATH::View` into an `AHTTP::Response` of the proper format.
#
# See the [Getting Started](/getting_started/routing/#content-negotiation) docs for more information.
module Athena::Framework::View::ViewHandlerInterface
  # The possible types for a view format handler.
  alias HandlerType = ATH::View::FormatHandlerInterface | Proc(ATH::View::ViewHandlerInterface, ATH::ViewBase, AHTTP::Request, String, AHTTP::Response)

  # Registers the provided *handler* to handle the provided *format*.
  abstract def register_handler(format : String, handler : ATH::View::ViewHandlerInterface::HandlerType) : Nil

  # Determines if `self` can handle the provided *format*.
  #
  # First checks if a custom format handler supports the provided *format*,
  # otherwise falls back on the `ASR::SerializerInterface`.
  abstract def supports?(format : String) : Bool

  # Handles the conversion of the provided *view* into an `AHTTP::Response`.
  #
  # If no *request* is provided, it is fetched from `AHTTP::RequestStore`.
  abstract def handle(view : ATH::ViewBase, request : AHTTP::Request? = nil) : AHTTP::Response

  # Creates an `AHTTP::Response` based on the provided *view* that'll redirect to the provided *location*.
  #
  # *location* may either be a `URL` or the name of a route.
  abstract def create_redirect_response(view : ATH::ViewBase, location : String, format : String) : AHTTP::Response

  # Creates an `AHTTP::Response` based on the provided *view* and *request*.
  abstract def create_response(view : ATH::ViewBase, request : AHTTP::Request, format : String) : AHTTP::Response
end
