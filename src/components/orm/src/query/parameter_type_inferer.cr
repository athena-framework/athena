# :nodoc:
#
# Infers the `Types::Type` a query parameter is converted through when none is given explicitly.
module Athena::ORM::Query::ParameterTypeInferer
  # Returns the type name for *value*, or `nil` when it should be bound without conversion.
  def self.infer_type(value : _) : String?
    case value
    when ::Int32 then Types::INTEGER
    when ::Int64 then Types::BIGINT
    when ::Bool  then Types::BOOLEAN
    when ::Time  then Types::DATETIME
    end
  end
end
