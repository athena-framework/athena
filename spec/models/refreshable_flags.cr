# Columns whose fresh values can be `false` or `nil`, which a refresh must still write back.
@[AORMA::Entity]
@[AORMA::Table(name: "refreshable_flags")]
class RefreshableFlags < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property? active : Bool = true

  @[AORMA::Column]
  property note : String? = nil
end
