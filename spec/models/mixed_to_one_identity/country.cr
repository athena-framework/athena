@[AORMA::Entity]
class Country < AORM::Entity
  @[AORMA::Column(length: 255)]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! country : String
end
