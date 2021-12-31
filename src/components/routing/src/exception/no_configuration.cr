require "./resource_not_found"

class Athena::Routing::Exception::NoConfiguration < Athena::Routing::Exception::ResourceNotFound
  include Athena::Routing::Exception
end
