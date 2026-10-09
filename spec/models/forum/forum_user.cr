@[AORMA::Entity]
@[AORMA::Table(name: "forum_users")]
class ForumUser < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  getter! id : Int32

  @[AORMA::Column(length: 50)]
  property! username : String

  @[AORMA::OneToOne(target_entity: ForumAvatar, cascade: ["persist"])]
  @[AORMA::JoinColumn(name: "avatar_id", referenced_column_id: "id")]
  property! avatar : ForumAvatar
end
