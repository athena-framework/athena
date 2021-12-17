require "./property_exception"

# Represents an error due to a missing required property that was not included in the input data.
#
# Exposes the missing property's name and type.
class Athena::Serializer::Exceptions::MissingRequiredProperty < Athena::Serializer::Exceptions::PropertyException
  getter property_type : String

  def initialize(property_name : String, @property_type : String)
    super "Missing required property: '#{property_name}'.", property_name
  end
end
