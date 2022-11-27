abstract class Athena::Validator::Constraints::Existence < Athena::Validator::Constraints::Composite
  def initialize(
    constraints : AVD::Constraints::Composite::Type = [] of AVD::Constraint,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super constraints, "", groups, payload
  end
end
