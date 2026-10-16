# Raised when an `AORM::Types::Type` that isn't registered is requested.
class Athena::ORM::Exception::UnknownColumnType < RuntimeError
  include Athena::ORM::Exception

  def initialize(name : String)
    super %(Unknown column type "#{name}" requested. Any type that you use has to be registered with `AORM::Types::Type.add_type`. You can get a list of all the known types with `AORM::Types::Type.type_map`.)
  end
end
