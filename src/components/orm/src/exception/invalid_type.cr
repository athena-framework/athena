require "./conversion"

# Raised when a Crystal value can't be converted to the database value of an `AORM::Types::Type`, because it's not one of the types it accepts.
class Athena::ORM::Exception::InvalidType < Athena::ORM::Exception::Conversion
  def initialize(value, to_type : String, possible_types : Enumerable(String), cause : ::Exception? = nil)
    described_value = case value
                      when String, Number, Bool, Nil then "value #{value.inspect}"
                      else                                "value of type #{value.class}"
                      end

    super "Could not convert #{described_value} to type #{to_type}. Expected one of the following types: #{possible_types.join ", "}.", cause
  end
end
