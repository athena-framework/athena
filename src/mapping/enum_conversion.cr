# :nodoc:
#
# Converts enum members to the integer values enum fields are stored as.
module Athena::ORM::Mapping::EnumConversion
  # Returns the integer *member* is stored as.
  # Base types wider than `Int32` are stored as `Int64` and narrower ones as `Int32`, so every stored value is one the drivers can bind.
  def self.from_enum(member : ::Enum)
    value = member.value
    value.is_a?(Int64 | UInt32 | UInt64) ? value.to_i64 : value.to_i32
  end
end
