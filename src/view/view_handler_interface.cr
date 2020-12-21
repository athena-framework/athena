module Athena::Routing::View::ViewHandlerInterface
  alias HandlerType = ART::View::FormatHandlerInterface | Proc(ART::View::ViewHandlerInterface, ART::ViewBase, HTTP::Request, String, ART::Response)

  abstract def register_handler(format : String, handler : ART::View::FormatHandlerInterface | Proc(ART::View::ViewHandlerInterface, ART::View, HTTP::Request, String, ART::Response)) : Nil
  abstract def supports?(format : String) : Bool
  abstract def handle(view : ART::View, request : HTTP::Request? = nil) : ART::Response
  abstract def create_redirect_response(view : ART::View, location : String, format : String) : ART::Response
  abstract def create_response(view : ART::View, request : HTTP::Request, format : String) : ART::Response
end
