@[ADI::Register(name: "request_store", public: true)]
# Stores the current `ATH::Request` object.
#
# Can be injected to access the request from a non controller context.
#
# ```
# require "athena"
#
# @[ADI::Register(public: true)]
# class ExampleController < ATH::Controller
#   def initialize(@request_store : ATH::RequestStore); end
#
#   get "/" do
#     @request_store.method
#   end
# end
#
# ATH.run
#
# # GET / # => GET
# ```
class Athena::Framework::RequestStore
  property! request : ATH::Request

  # Resets the store, removing the reference to the request.
  #
  # Used internally after the response has been returned.
  protected def reset : Nil
    @request = nil
  end
end
