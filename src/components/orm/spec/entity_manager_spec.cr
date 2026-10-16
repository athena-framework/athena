require "./spec_helper"

# Composite-PK fixture: two String identifiers form the primary key.
@[AORMA::Entity]
@[AORMA::Table(name: "composite_keyed")]
class CompositeKeyed < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property tenant : String? = nil

  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property record : String? = nil
end

struct EntityManagerTest < ASPEC::TestCase
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @em = MockEntityManager.new MockConnection.new
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  def test_find_with_full_composite_id_hash_succeeds : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CompositeKeyed
    @uow.set_entity_persister CompositeKeyed, persister
    persister.mock_load_by_id_result = nil

    @em.find CompositeKeyed, {"tenant" => "acme", "record" => "42"}

    persister.load_by_id_calls.size.should eq 1
    persister.load_by_id_calls.first.keys.sort!.should eq ["record", "tenant"]
  end

  def test_find_with_partial_composite_id_hash_raises : Nil
    expect_raises(AORM::Exception::MissingIdentifierField, "The identifier record is missing for a query of CompositeKeyed") do
      @em.find CompositeKeyed, {"tenant" => "acme"}
    end
  end

  def test_find_with_scalar_against_composite_pk_raises : Nil
    expect_raises(AORM::Exception::ORMInvalidArgument, "Binding an entity with a composite primary key to a query is not supported.") do
      @em.find CompositeKeyed, "acme"
    end
  end

  def test_find_with_extra_id_field_raises : Nil
    expect_raises(AORM::Exception::UnrecognizedIdentifierFields, %(Unrecognized identifier fields: "extra" are not present on class "CompositeKeyed".)) do
      @em.find CompositeKeyed, {"tenant" => "acme", "record" => "42", "extra" => "ignored"}
    end
  end

  # Keys of the identifier would otherwise end up in the SQL loading the entity.
  def test_find_injection_prevented : Nil
    expect_raises(AORM::Exception::UnrecognizedIdentifierFields, "Unrecognized identifier fields: ") do
      @em.repository(CmsUser).find({"username = ?; DELETE FROM cms_users; SELECT 1 WHERE 1" => "test", "id" => 1})
    end
  end

  def test_contains_new_persisted_and_removed_entities : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CompositeKeyed
    @uow.set_entity_persister CompositeKeyed, persister

    entity = CompositeKeyed.new
    entity.tenant = "t"
    entity.record = "r"

    @em.contains(entity).should be_false

    @em.persist entity
    @em.contains(entity).should be_true

    managed = CompositeKeyed.new
    managed.tenant = "t"
    managed.record = "managed"
    @uow.register_managed managed, {"tenant" => "t", "record" => "managed"}, {"tenant" => "t", "record" => "managed"}
    @em.contains(managed).should be_true

    @em.remove managed
    @em.contains(managed).should be_false
  end

  def test_closed_entity_manager_raises : Nil
    @em.close

    expect_raises AORM::Exception::EntityManagerClosed, "The EntityManager is closed." do
      @em.persist CompositeKeyed.new
    end
  end
end
