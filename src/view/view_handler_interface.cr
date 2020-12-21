module Athena::Routing::View::ViewHandlerInterface
  # TODO: Allow defining custom view handlers.
  # abstract def register_handler(format : String, &callback) : Nil

  abstract def supports?(format : String) : Bool

  abstract def handle(view : ART::View, request : HTTP::Request? = nil) : ART::Response
  # abstract def create_redirect_response(view : ART::View, location : String, format : String) : ART::Response
  abstract def create_response(view : ART::View, request : HTTP::Request, format : String) : ART::Response
end
