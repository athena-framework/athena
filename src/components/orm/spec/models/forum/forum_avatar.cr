@[AORMA::Entity]
@[AORMA::Table(name: "forum_avatars")]
class ForumAvatar < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  getter! id : Int32
end
