require "../../spec_helper"

# Tracks calls to `resolve_pending_to_one_associations` so a spec can assert
# the abstract hydrator's `cleanup` ran even when `hydrate_all_data` raised.
private class CleanupTrackingUow < MockUnitOfWork
  getter resolve_pending_call_count : Int32 = 0

  def resolve_pending_to_one_associations : Nil
    @resolve_pending_call_count += 1
    super
  end
end

# Subclass that throws from `hydrate_all_data` so we can verify the `ensure` branch in `Abstract#hydrate_all` runs `cleanup` on the way out.
private class RaisingHydrator < AORM::Internal::Hydrators::SimpleObject
  protected def hydrate_all_data : Array(AORM::Entity)
    raise "boom"
  end
end

struct AbstractHydratorTest < ASPEC::TestCase
  # `Abstract#hydrate_all` wraps `hydrate_all_data` in an `ensure cleanup`.
  # If hydration raises mid-iteration the exception must propagate AND `cleanup` must still run, which in turn fires `resolve_pending_to_one_associations` so any deferred ToOne loads get drained or discarded along with the cursor.
  def test_hydrate_all_runs_cleanup_even_when_hydration_raises : Nil
    em = MockEntityManager.new(MockConnection.new)
    uow = CleanupTrackingUow.new em
    em.uow_mock = uow

    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    rs = FakeResultSet.new([] of Hash(String, DB::Any))

    expect_raises(Exception, /boom/) do
      RaisingHydrator.new(em).hydrate_all(rs, rsm)
    end

    uow.resolve_pending_call_count.should eq 1
  end

  # `Abstract#gather_row_data` must consume every column — columns that aren't mapped in the RSM still need an `rs.read` to keep the cursor aligned.
  # Routes through `Object#hydrate_row_data → gather_row_data` (the only path that actually calls `gather_row_data`).
  def test_gather_row_data_skips_unmapped_columns : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    rs = FakeResultSet.new([
      {
        "p__phonenumber" => "555-X".as(DB::Any),
        "extra_unmapped" => "ignored".as(DB::Any),
      },
    ])

    result = AORM::Internal::Hydrators::Object.new(em).hydrate_all(rs, rsm)

    result.size.should eq 1
    result[0].as(CmsPhonenumber).phonenumber.should eq "555-X"
  end
end
