require "./persister"

# Raised when entities are ordered by a direction other than `ASC` or `DESC`.
class Athena::ORM::Exception::InvalidOrientation < Athena::ORM::Exception::Persister
  def self.from_class_name_and_field(class_name : String, field : String) : self
    new "Invalid order by orientation specified for #{class_name}##{field}"
  end
end
