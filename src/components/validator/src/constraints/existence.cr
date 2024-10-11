# See [AVD::Constraints::Collection][Athena::Validator::Constraints::Collection--required-and-optional-constraints] for more information.
abstract class Athena::Validator::Constraints::Existence < Athena::Validator::Constraints::Composite
  def initialize(
    constraints : Array(AVD::Constraint) | AVD::Constraint = [] of AVD::Constraint,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super constraints, "", groups, payload
  end
end
