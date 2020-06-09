@[ADI::Register(name: "request_store", public: true)]
# Stores the current `HTTP::Request` object.
#
# Can be injected to access the request from a non controller context.
#
# ```
# require "athena"
#
# @[ADI::Register(public: true)]
# class ExampleController < ART::Controller
#   def initialize(@request_store : ART::RequestStore); end
#
#   get "/" do
#     @request_store.method
#   end
# end
#
# ART.run
#
# # GET / # => GET
# ```
class Athena::Routing::RequestStore
  property! request : HTTP::Request

  # Resets the store, removing the reference to the request.
  #
  # Used internally after the request has been returned.
  protected def reset : Nil
    @request = nil
  end
end
