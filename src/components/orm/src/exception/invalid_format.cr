require "./conversion"

# Raised when a value read from the database isn't in the format an `AORM::Types::Type` expects, such as an unparsable date and time.
class Athena::ORM::Exception::InvalidFormat < Athena::ORM::Exception::Conversion
  def initialize(value : String, to_type : String, expected_format : String?, cause : ::Exception? = nil)
    super %(Could not convert database value "#{value.size > 32 ? "#{value[0, 20]}..." : value}" to type #{to_type}. Expected format "#{expected_format}".), cause
  end
end
