@[AORMA::Entity]
@[AORMA::Table(name: "cms_users")]
class CmsUser < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column(length: 50)]
  property! username : String

  @[AORMA::ManyToMany(target_entity: CmsGroup, inversed_by: "users", cascade: ["persist"])]
  property groups : AORM::Collection(CmsGroup) = AORM::ArrayCollection(CmsGroup).new

  # Owning-side helper that keeps both ends consistent
  def add_group(group : CmsGroup) : Nil
    self.groups << group
    group.add_user self
  end
end
