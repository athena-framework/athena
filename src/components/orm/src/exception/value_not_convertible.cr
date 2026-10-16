require "./conversion"

# Raised when a value read from the database can't be converted to the Crystal value of an `AORM::Types::Type`.
class Athena::ORM::Exception::ValueNotConvertible < Athena::ORM::Exception::Conversion
  def initialize(value : String, to_type : String, message : String? = nil, cause : ::Exception? = nil)
    message = if message
                %(Could not convert database value to "#{to_type}" as an error was triggered by the unserialization: #{message})
              else
                %(Could not convert database value "#{value.size > 32 ? "#{value[0, 20]}..." : value}" to type "#{to_type}".)
              end

    super message, cause
  end
end
