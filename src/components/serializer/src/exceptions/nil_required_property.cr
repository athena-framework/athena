require "./property_exception"

# Represents an error due to a required property that was `nil`.
#
# Exposes the property's name and type.
class Athena::Serializer::Exceptions::NilRequiredProperty < Athena::Serializer::Exceptions::PropertyException
  getter property_type : String

  def initialize(property_name : String, @property_type : String)
    super "Required property '#{property_name}' cannot be nil.", property_name
  end
end
