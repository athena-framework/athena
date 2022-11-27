class Athena::Validator::Constraints::Optional < Athena::Validator::Constraints::Existence
  # :inherit:
  def validated_by : NoReturn
    raise "BUG: #{self} cannot be validated"
  end
end
