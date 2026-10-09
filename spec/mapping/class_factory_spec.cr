require "../spec_helper"

@[AORMA::Entity]
class SequenceIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :sequence)]
  property id : Int64? = nil
end

@[AORMA::Entity]
class CustomIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :custom)]
  property id : Int64? = nil
end

struct ClassFactoryTest < ASPEC::TestCase
  @[DataProvider("unsupported_id_generation_strategies")]
  def test_unsupported_id_generation_strategy_is_rejected(entity_class : AORM::Entity.class, message : String) : Nil
    em = MockEntityManager.new MockConnection.new

    expect_raises(Exception, message) do
      em.class_metadata entity_class
    end
  end

  def unsupported_id_generation_strategies : Hash
    {
      "SEQUENCE" => {SequenceIdFixture, "'SequenceIdFixture': the SEQUENCE ID generation strategy is not supported yet."},
      "CUSTOM"   => {CustomIdFixture, "'CustomIdFixture': the CUSTOM ID generation strategy is not supported yet."},
    }
  end
end
