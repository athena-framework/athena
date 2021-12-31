class Athena::Routing::Exception::MethodNotAllowed < RuntimeError
  include Athena::Routing::Exception

  getter allowed_methods : Array(String)

  def initialize(allowed_methods : Enumerable(String), message : String? = nil, cause : ::Exception? = nil)
    @allowed_methods = allowed_methods.map &.upcase
    super message, cause
  end
end
