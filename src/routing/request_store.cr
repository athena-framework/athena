@[Athena::DI::Register]
# Stores the currnet `HTTP::Request` object.
#
# Can be injected to get access to the current request.
class Athena::Routing::RequestStore
  include Athena::DI::Service

  property request : HTTP::Request? = nil
end
