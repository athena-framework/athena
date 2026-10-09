# Identifier and field both typed as a value object, mapped through `CustomIdObjectType`.
@[AORMA::Entity]
@[AORMA::Table(name: "custom_id_type_parent")]
class CustomIdObjectTypeParent < AORM::Entity
  @[AORMA::Column(type: "CustomIdObject")]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : CustomIdObject

  @[AORMA::Column(type: "CustomIdObject")]
  property other_id : CustomIdObject? = nil

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "custom_id_type_parent_tag")]
  @[AORMA::JoinColumn(name: "parent_id", referenced_column_name: "id")]
  @[AORMA::InverseJoinColumn(name: "tag_id", referenced_column_name: "id")]
  property tags : AORM::Collection(CustomIdObjectTypeTag) = AORM::ArrayCollection(CustomIdObjectTypeTag).new
end

# ManyToMany target whose identifier is a value object, so join-table rows bind converted identifiers on both sides.
@[AORMA::Entity]
@[AORMA::Table(name: "custom_id_type_tag")]
class CustomIdObjectTypeTag < AORM::Entity
  @[AORMA::Column(type: "CustomIdObject")]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : CustomIdObject
end
