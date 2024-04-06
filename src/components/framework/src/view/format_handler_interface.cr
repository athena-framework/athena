# Represents custom logic that should be applied for a specific format in order to render an `ATH::View` into an `ATH::Response`
# that is not handled by default by Athena. E.g. `HTML`.
#
# ```
# # Register our handler as a service.
# @[ADI::Register]
# class HTMLFormatHandler
#   # Implement the interface.
#   include Athena::Framework::View::FormatHandlerInterface
#
#   # :inherit:
#   #
#   # Turn the provided data into a response that can be returned to the client.
#   def call(view_handler : ATH::View::ViewHandlerInterface, view : ATH::ViewBase, request : ATH::Request, format : String) : ATH::Response
#     ATH::Response.new "<h1>#{view.data}</h1>", headers: HTTP::Headers{"content-type" => "text/html"}
#   end
#
#   # :inherit:
#   #
#   # Specify that `self` handles the `HTML` format.
#   def format : String
#     "html"
#   end
# end
# ```
#
# The implementation for `HTML` for example could use `.to_s` as depicted here, or utilize a templating engine, possibly taking advantage
# of [custom annotations](/getting_started/configuration#custom-annotations) to allow specifying the related template name.
@[ADI::Autoconfigure(tags: [Athena::Framework::View::FormatHandlerInterface::TAG])]
module Athena::Framework::View::FormatHandlerInterface
  TAG = "athena.format_handler"

  # Responsible for returning an `ATH::Response` for the provided *view* and *request* in the provided *format*.
  #
  # The `ATH::View::ViewHandlerInterface` is also provided to ease response creation.
  abstract def call(view_handler : ATH::View::ViewHandlerInterface, view : ATH::View, request : ATH::Request, format : String) : ATH::Response

  # Returns the format that `self` handles.
  #
  # The *format* must be registered with the `ATH::Request::FORMATS` hash;
  # either as a built in format, or a custom one that has registered via `ATH::Request.register_format`.
  abstract def format : String
end
