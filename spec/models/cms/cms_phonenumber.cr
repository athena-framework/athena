@[AORMA::Entity]
@[AORMA::Table(name: "cms_phonenumbers")]
class CmsPhonenumber < AORM::Entity
  @[AORMA::Column(length: 50)]
  @[AORMA::ID]
  property! phonenumber : String
end
