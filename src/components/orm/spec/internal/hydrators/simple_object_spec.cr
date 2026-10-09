require "../../spec_helper"

struct SimpleObjectHydratorTest < ASPEC::TestCase
  # Single root entity, single row → exactly one entity in the result.
  def test_hydrates_a_single_row_into_one_entity : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    rs = FakeResultSet.new([
      {"p__phonenumber" => "555-0100".as(DB::Any)},
    ])

    result = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)

    result.size.should eq 1
    result[0].should be_a CmsPhonenumber
    result[0].as(CmsPhonenumber).phonenumber.should eq "555-0100"
  end

  # Field values are produced by the field's type, so they may be any Crystal type rather than only the driver's scalars.
  def test_hydrates_value_object_fields_through_their_type : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CustomIdObjectTypeParent, "p"
    rsm.add_field_result "p", "p__id", "id"
    rsm.add_field_result "p", "p__other_id", "other_id"

    rs = FakeResultSet.new([
      {"p__id" => "abc".as(DB::Any), "p__other_id" => "def".as(DB::Any)},
    ])

    parent = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm).first.as(CustomIdObjectTypeParent)

    parent.id.should eq CustomIdObject.new("abc")
    parent.other_id.should eq CustomIdObject.new("def")
  end

  # A NULL column is part of the row too: refreshing must overwrite the in-memory value with it.
  def test_refresh_writes_null_columns_back : Nil
    em = MockEntityManager.new(MockConnection.new)
    entity = RefreshableFlags.new
    entity.id = 7
    entity.note = "stale"
    em.unit_of_work.register_managed entity, {"id" => 7}, {"id" => 7, "active" => true, "note" => "stale"}

    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result RefreshableFlags, "r"
    rsm.add_field_result "r", "r__id", "id"
    rsm.add_field_result "r", "r__note", "note"

    rs = FakeResultSet.new([{"r__id" => 7.as(DB::Any), "r__note" => nil.as(DB::Any)}])
    AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm, AORM::Query::Hints.new(refresh: true))

    entity.note.should be_nil
  end

  def test_hydrates_multiple_rows_into_multiple_entities : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    rs = FakeResultSet.new([
      {"p__phonenumber" => "555-0001".as(DB::Any)},
      {"p__phonenumber" => "555-0002".as(DB::Any)},
      {"p__phonenumber" => "555-0003".as(DB::Any)},
    ])

    result = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)

    result.map(&.as(CmsPhonenumber).phonenumber).should eq ["555-0001", "555-0002", "555-0003"]
  end

  # Doctrine: testExtraFieldInResultSetShouldBeIgnore. Columns the RSM hasn't
  # mapped (e.g., a window-function `rownum` tagged on by the platform) should
  # be silently dropped instead of raising.
  def test_extra_columns_in_the_result_set_are_ignored : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    rs = FakeResultSet.new([
      {
        "p__phonenumber" => "555-0200".as(DB::Any),
        "rownum"         => "1".as(DB::Any),
      },
    ])

    result = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)

    result.size.should eq 1
    result[0].as(CmsPhonenumber).phonenumber.should eq "555-0200"
  end

  # The hydrator's `prepare` step asserts that the RSM models a single root
  # entity — anything richer needs the full ObjectHydrator.
  def test_prepare_rejects_an_rsm_with_more_than_one_alias : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_entity_result CmsUser, "u"

    rs = FakeResultSet.new([] of Hash(String, DB::Any))

    expect_raises(Exception, /more than one object result/) do
      AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)
    end
  end

  # ToOne owning-side FK columns are registered in the RSM as meta results.
  # The hydrator must route them into the per-entity row data hash so
  # `UnitOfWork#create_entity` can resolve the association. Reusing
  # MockUnitOfWork here lets us drive the full hydrate → defer → resolve flow
  # without standing up a real DB connection.
  def test_meta_column_routes_through_hydrator_into_to_one_resolution : Nil
    em = MockEntityManager.new(MockConnection.new)
    uow = MockUnitOfWork.new em
    em.uow_mock = uow

    canned_avatar = ForumAvatar.new
    pointerof(canned_avatar.@id).value = 42

    avatar_persister = MockEntityPersister.new em, em.class_metadata(ForumAvatar)
    avatar_persister.mock_load_result = canned_avatar
    uow.set_entity_persister ForumAvatar, avatar_persister

    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result ForumUser, "u"
    rsm.add_field_result "u", "u__id", "id"
    rsm.add_field_result "u", "u__username", "username"
    rsm.add_meta_result "u", "u__avatar_id", "avatar_id", false, "integer"

    rs = FakeResultSet.new([
      {
        "u__id"        => 7.as(DB::Any),
        "u__username"  => "fred".as(DB::Any),
        "u__avatar_id" => 42.as(DB::Any),
      },
    ])

    result = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)

    result.size.should eq 1
    user = result[0].as(ForumUser)
    user.username.should eq "fred"
    # `cleanup` ran the deferred resolution — avatar should be populated.
    user.avatar.should be canned_avatar
    avatar_persister.load_calls.size.should eq 1
  end

  # Cursor invariant regression: mixing mapped and unmapped columns across
  # multiple rows must not desync the cursor. Specifically, the unmapped-column
  # branch must call `rs.read` to advance — otherwise the next row's columns
  # shift and we get scrambled values.
  def test_unmapped_columns_do_not_desync_the_cursor_across_rows : Nil
    em = MockEntityManager.new(MockConnection.new)
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result CmsPhonenumber, "p"
    rsm.add_field_result "p", "p__phonenumber", "phonenumber"

    # Each row carries an unmapped `rownum` between… no, actually before a
    # mapped column. If the unmapped branch forgets to advance, the mapped
    # read on row 2 will pick up row 1's leftover and assertions blow up.
    rs = FakeResultSet.new([
      {"rownum" => "1".as(DB::Any), "p__phonenumber" => "555-A".as(DB::Any)},
      {"rownum" => "2".as(DB::Any), "p__phonenumber" => "555-B".as(DB::Any)},
      {"rownum" => "3".as(DB::Any), "p__phonenumber" => "555-C".as(DB::Any)},
    ])

    result = AORM::Internal::Hydrators::SimpleObject.new(em).hydrate_all(rs, rsm)

    result.map(&.as(CmsPhonenumber).phonenumber).should eq ["555-A", "555-B", "555-C"]
  end
end
