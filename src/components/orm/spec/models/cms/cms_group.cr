@[AORMA::Entity]
@[AORMA::Table(name: "cms_groups")]
class CmsGroup < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column(length: 50)]
  property! name : String

  @[AORMA::ManyToMany(target_entity: CmsUser, mapped_by: "groups")]
  property users : AORM::Collection(CmsUser) = AORM::ArrayCollection(CmsUser).new

  # Inverse-side helper invoked from `CmsUser#add_group` (does not recurse).
  def add_user(user : CmsUser) : Nil
    self.users << user
  end
end
