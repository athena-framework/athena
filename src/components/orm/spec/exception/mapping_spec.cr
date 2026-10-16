require "../spec_helper"

# The checks raising these can't be reached through the annotation driver, which rejects such mappings at compile time or always sets what they check.
struct MappingTest < ASPEC::TestCase
  def test_missing_target_entity : Nil
    AORM::Exception::Mapping.missing_target_entity("avatar").message.should eq "The association mapping 'avatar' misses the 'target_entity' attribute."
  end

  def test_invalid_association_type : Nil
    AORM::Exception::Mapping.invalid_association_type("ForumUser", "avatar", "one_to_none").message.should eq %(The association "ForumUser#avatar" must be of type "one_to_one", "one_to_many", "many_to_many" or "many_to_one", "one_to_none" given.)
  end

  def test_illegal_lifecycle_callback_on_embedded_class : Nil
    AORM::Exception::Mapping.illegal_lifecycle_callback_on_embedded_class(AORM::Events::PrePersistEventArgs(ForumUser), "ForumUser").message.should eq <<-MESSAGE
      Context: Attempt to register lifecycle callback "Athena::ORM::Events::PrePersistEventArgs(ForumUser)" on embedded class "ForumUser".
      Problem: Registering lifecycle callbacks on embedded classes is not allowed.
      MESSAGE
  end

  def test_invalid_attribute_on_embeddable : Nil
    AORM::Exception::Mapping.invalid_attribute_on_embeddable("ForumUser", "OneToOne").message.should eq %(Attribute "OneToOne" on embeddable "ForumUser" is not allowed.)
  end

  def test_join_column_must_point_to_mapped_field : Nil
    AORM::Exception::Mapping.join_column_must_point_to_mapped_field("ForumUser", "avatar_id").message.should eq "The column avatar_id must be mapped to a field in class ForumUser since it is referenced by a join column of another class."
  end
end
