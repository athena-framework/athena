require "../spec_helper"

# An entity describing itself, used as the entity found through a relationship.
@[AORMA::Entity]
class StringableExceptionEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property! id : Int32

  def to_s(io : IO) : Nil
    io << "ThisIsAStringRepresentationOfEntity3"
  end
end

struct ORMInvalidArgumentTest < ASPEC::TestCase
  @em : MockEntityManager

  def initialize
    @em = MockEntityManager.new MockConnection.new
  end

  def test_new_entities_found_through_relationships_one_entity_found : Nil
    entity = ForumAvatar.new

    exception = AORM::Exception::ORMInvalidArgument.new_entities_found_through_relationships [{self.association(ForumUser, "avatar"), entity.as(AORM::Entity)}]

    exception.message.should eq "A new entity was found through the relationship 'ForumUser#avatar' that was not configured to cascade persist operations for entity: #{entity}. " \
                                "To solve this issue: Either explicitly call EntityManager#persist on this unknown entity or configure cascade persist this association in the mapping for example @[AORMA::ManyToOne(..., cascade: [\"persist\"])]."
  end

  def test_new_entities_found_through_relationships_two_entities_found : Nil
    entity1 = ForumAvatar.new
    entity2 = ValueConversionType::InversedOneToManyEntity.new

    exception = AORM::Exception::ORMInvalidArgument.new_entities_found_through_relationships [
      {self.association(ForumUser, "avatar"), entity1.as(AORM::Entity)},
      {self.association(ValueConversionType::OwningManyToOneEntity, "associated_entity"), entity2.as(AORM::Entity)},
    ]

    exception.message.should eq "Multiple non-persisted new entities were found through the given association graph:\n\n" \
                                " * A new entity was found through the relationship 'ForumUser#avatar' that was not configured to cascade persist operations for entity: #{entity1}. " \
                                "To solve this issue: Either explicitly call EntityManager#persist on this unknown entity or configure cascade persist this association in the mapping for example @[AORMA::ManyToOne(..., cascade: [\"persist\"])].\n" \
                                " * A new entity was found through the relationship 'ValueConversionType::OwningManyToOneEntity#associated_entity' that was not configured to cascade persist operations for entity: #{entity2}. " \
                                "To solve this issue: Either explicitly call EntityManager#persist on this unknown entity or configure cascade persist this association in the mapping for example @[AORMA::ManyToOne(..., cascade: [\"persist\"])]."
  end

  def test_new_entities_found_through_relationships_describes_the_entity_with_to_s : Nil
    exception = AORM::Exception::ORMInvalidArgument.new_entities_found_through_relationships [{self.association(ForumUser, "avatar"), StringableExceptionEntity.new.as(AORM::Entity)}]

    exception.message.should eq "A new entity was found through the relationship 'ForumUser#avatar' that was not configured to cascade persist operations for entity: ThisIsAStringRepresentationOfEntity3. " \
                                "To solve this issue: Either explicitly call EntityManager#persist on this unknown entity or configure cascade persist this association in the mapping for example @[AORMA::ManyToOne(..., cascade: [\"persist\"])]."
  end

  def test_schedule_insert_messages : Nil
    entity = StringableExceptionEntity.new

    AORM::Exception::ORMInvalidArgument.schedule_insert_for_managed_entity(entity).message.should eq "A managed+dirty entity ThisIsAStringRepresentationOfEntity3 can not be scheduled for insertion."
    AORM::Exception::ORMInvalidArgument.schedule_insert_for_removed_entity(entity).message.should eq "Removed entity ThisIsAStringRepresentationOfEntity3 can not be scheduled for insertion."
    AORM::Exception::ORMInvalidArgument.schedule_insert_twice(entity).message.should eq "Entity ThisIsAStringRepresentationOfEntity3 can not be scheduled for insertion twice."
  end

  def test_invalid_association : Nil
    exception = AORM::Exception::ORMInvalidArgument.invalid_association self.association(ForumUser, "avatar"), "Array(ForumAvatar)"

    exception.message.should eq %(Expected value of type "ForumAvatar" for association field "ForumUser#avatar", got "Array(ForumAvatar)" instead.)
  end

  private def association(entity_class : AORM::Entity.class, field_name : String) : AORM::Mapping::Association
    @em.class_metadata(entity_class).association_mappings[field_name]
  end
end
