# Represents an error due to an invalid property.
#
# Exposes the property's name.
class Athena::Serializer::Exception::PropertyException < RuntimeError
  include Athena::Serializer::Exception

  getter property_name : String

  def initialize(message : String, @property_name : String)
    super message
  end
end
