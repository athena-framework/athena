require "./persister"

# Raised when entities are searched for or ordered by a field the entity doesn't map.
class Athena::ORM::Exception::UnrecognizedField < Athena::ORM::Exception::Persister
  def self.by_fully_qualified_name(class_name : String, field : String) : self
    new "Unrecognized field: #{class_name}##{field}"
  end
end
