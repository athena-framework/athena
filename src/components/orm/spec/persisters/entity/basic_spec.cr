require "../../spec_helper"

# Composite-PK fixture for ORDER BY coverage.
@[AORMA::Entity]
@[AORMA::Table(name: "composite_pk_items")]
class CompositePkItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property tenant_id : String? = nil

  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property item_id : String? = nil

  @[AORMA::Column]
  property! label : String
end

# Composite-PK + auto-gen: only viable through the RETURNING path, since
# `LASTVAL()` can only return a single column.
@[AORMA::Entity]
@[AORMA::Table(name: "composite_auto_items")]
class CompositeAutoItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! tenant_id : Int64

  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! item_id : Int64

  @[AORMA::Column]
  property! label : String
end

# Self-referencing many-to-many with explicit join columns, so removing an entity deletes its join table rows from both sides.
@[AORMA::Entity]
@[AORMA::Table(name: "customtype_parents")]
class JoinRowsParent < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::ManyToMany(mapped_by: "my_friends")]
  property friends_with_me : AORM::Collection(JoinRowsParent) = AORM::ArrayCollection(JoinRowsParent).new

  @[AORMA::ManyToMany(inversed_by: "friends_with_me")]
  @[AORMA::JoinTable(name: "customtype_parent_friends")]
  @[AORMA::JoinColumn(name: "customtypeparent_id", referenced_column_name: "id")]
  @[AORMA::InverseJoinColumn(name: "friend_customtypeparent_id", referenced_column_name: "id")]
  property my_friends : AORM::Collection(JoinRowsParent) = AORM::ArrayCollection(JoinRowsParent).new
end

@[AORMA::Entity]
@[AORMA::Table(name: "default_join_rows_tags")]
class DefaultJoinRowsTag < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil
end

# Many-to-many with default join columns, which are `ON DELETE CASCADE`.
@[AORMA::Entity]
@[AORMA::Table(name: "default_join_rows_owners")]
class DefaultJoinRowsOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::ManyToMany]
  property tags : AORM::Collection(DefaultJoinRowsTag) = AORM::ArrayCollection(DefaultJoinRowsTag).new
end

@[AORMA::Entity]
@[AORMA::Table(name: "unmapped_property_items")]
class UnmappedPropertyItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::Column]
  property name : String = ""

  # Not mapped to a column.
  property? greeted : Bool = false
end

# Column whose type converts values in SQL.
@[AORMA::Entity]
@[AORMA::Table(name: "sql_converted_items")]
class SqlConvertedItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::Column(type: "upper_case_string")]
  property! name : String
end

# Identifier whose column name differs from its field name.
@[AORMA::Entity]
@[AORMA::Table(name: "renamed_pk_items")]
class RenamedPkItem < AORM::Entity
  @[AORMA::Column(name: "item_pk")]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32
end

# Identifier and field both mapped through a reversible conversion type, so bound values reveal whether they passed through it.
@[AORMA::Entity]
@[AORMA::Table(name: "rot13_items")]
class Rot13Item < AORM::Entity
  @[AORMA::Column(type: "rot13")]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : String

  @[AORMA::Column(type: "rot13")]
  property! secret : String
end

@[AORMA::Entity]
@[AORMA::Table(name: "timestamped_items")]
class TimestampedItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! created_at : Time
end

# Binary column, whose `Bytes` values must bind as a single parameter rather than an IN list.
@[AORMA::Entity]
@[AORMA::Table(name: "binary_items")]
class BinaryItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! data : Bytes
end

# OneToMany inverse-side / ManyToOne owning-side pair, used to drive the inverse-side branch in `select_condition_statement_column_sql`.
@[AORMA::Entity]
@[AORMA::Table(name: "tag_owners")]
class TagOwnerWithTags < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::OneToMany(mapped_by: "owner")]
  property tags : AORM::Collection(OwnedTag) = AORM::ArrayCollection(OwnedTag).new
end

@[AORMA::Entity]
@[AORMA::Table(name: "owned_tags")]
class OwnedTag < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::ManyToOne]
  property owner : TagOwnerWithTags? = nil
end

struct BasicPersisterTest < ASPEC::TestCase
  def test_select_condition_eq_emits_placeholder : Nil
    persister = build_persister

    persister.select_condition_statement_sql("id", 1).should match(/id = \?/)
  end

  # Only arrays expand into an IN list; `Bytes` is a single binary value even though it's enumerable.
  def test_select_condition_binary_value_emits_a_single_placeholder : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(BinaryItem)

    persister.select_condition_statement_sql("data", Bytes[1, 2, 3]).should match(/data = \?$/)
  end

  def test_expand_parameters_binds_a_binary_value_as_one_parameter : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(BinaryItem)

    params, _types = persister.expand_parameters({"data" => Bytes[1, 2, 3]})

    params.size.should eq 1
    params.first.value.should eq Bytes[1, 2, 3]
  end

  def test_select_condition_eq_nil_emits_is_null : Nil
    persister = build_persister

    persister.select_condition_statement_sql("id", nil).should match(/id IS NULL/)
  end

  def test_select_condition_neq_nil_emits_is_not_null : Nil
    persister = build_persister

    persister.select_condition_statement_sql("id", nil, comparison: "<>").should match(/id IS NOT NULL/)
  end

  def test_select_condition_array_emits_in_clause : Nil
    persister = build_persister

    sql = persister.select_condition_statement_sql("id", [1, 2, 3])

    sql.should match(/id IN \(\?, \?, \?\)/)
  end

  def test_select_condition_empty_array_emits_unsatisfiable : Nil
    persister = build_persister

    persister.select_condition_statement_sql("id", [] of Int32).should match(/1=0/)
  end

  def test_select_condition_array_with_nil_adds_is_null_branch : Nil
    persister = build_persister

    sql = persister.select_condition_statement_sql("id", [1, nil, 2])

    # Two non-nil values plus a NULL branch. Column is qualified by table alias.
    sql.should match(/\(t\d+\.id IN \(\?, \?\) OR t\d+\.id IS NULL\)/)
  end

  def test_select_condition_array_of_only_nils_emits_is_null : Nil
    persister = build_persister

    persister.select_condition_statement_sql("id", [nil, nil] of Int32?).should match(/id IS NULL/)
  end

  def test_select_condition_to_one_owning_side_emits_join_column : Nil
    persister = build_persister

    avatar = ForumAvatar.new

    sql = persister.select_condition_statement_sql("avatar", avatar)

    # ForumUser maps `avatar` via `@[AORMA::JoinColumn(name: "avatar_id", ...)]`
    sql.should match(/avatar_id = \?/)
  end

  def test_expand_parameters_skips_nil : Nil
    persister = build_persister

    params, types = persister.expand_parameters({"id" => nil.as(DB::Any)})

    params.should be_empty
    types.should be_empty
  end

  def test_expand_parameters_flattens_array_and_drops_nils : Nil
    persister = build_persister

    params, _types = persister.expand_parameters({"id" => [1, nil, 3].as(Array(Int32?))})

    params.size.should eq 2
  end

  def test_expand_parameters_resolves_an_entity_to_its_identifier_value : Nil
    persister = build_persister

    avatar = ForumAvatar.new
    em = persister.@em
    em.unit_of_work.register_managed avatar, {"id" => 99}, {"id" => 99}

    params, _types = persister.expand_parameters({"avatar" => avatar})

    params.size.should eq 1
    params.first.value.should eq 99
  end

  def test_prepare_insert_data_writes_to_one_owning_side_fk_column : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = MockEntityPersister.new em, em.class_metadata(ForumUser)

    avatar = ForumAvatar.new
    em.unit_of_work.register_managed avatar, {"id" => 99}, {"id" => 99}

    user = ForumUser.new
    user.username = "fred"
    user.avatar = avatar

    em.unit_of_work.persist user
    em.unit_of_work.compute_changesets

    data = persister.insert_data_for user
    user_row = data["forum_users"]

    user_row["username"].value.should eq "fred"
    # avatar_id mirrors the avatar's identifier so the FK is written on insert.
    user_row["avatar_id"].value.should eq 99
  end

  def test_prepare_insert_data_writes_null_fk_when_target_still_queued : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = MockEntityPersister.new em, em.class_metadata(ForumUser)

    avatar = ForumAvatar.new
    user = ForumUser.new
    user.username = "fred"
    user.avatar = avatar

    # Both entities are scheduled for insert and the target has no identifier
    # yet: the FK column gets NULL on this INSERT and an extra UPDATE gets
    # scheduled to patch it once the target has an id.
    em.unit_of_work.persist user
    em.unit_of_work.compute_changesets

    data = persister.insert_data_for user
    user_row = data["forum_users"]

    user_row["avatar_id"].value.should be_nil
    em.unit_of_work.extra_update_for(user).has_key?("avatar").should be_true
  end

  def test_insert_sql_lists_columns_and_placeholders : Nil
    persister = build_persister

    sql = persister.insert_sql

    sql.should start_with "INSERT INTO"
    sql.should match /\bforum_users\b/
    # ForumUser has username (column) + avatar (FK via @[AORMA::JoinColumn(name: "avatar_id")])
    sql.should match /\busername\b/
    sql.should match /\bavatar_id\b/
    # ID column is identity-strategy → omitted from the explicit column list.
    sql.should_not match /\(.*\bid\b.*\)/
  end

  def test_insert_column_list_emits_join_columns_for_to_one_owning_side : Nil
    persister = build_persister

    columns = persister.insert_column_list

    # ForumUser → avatar is a ToOne owning side mapped to "avatar_id".
    columns.should contain "avatar_id"
    columns.should contain "username"
  end

  def test_select_condition_sql_joins_multiple_predicates_with_and : Nil
    persister = build_persister

    sql = persister.select_condition_sql({"id" => 1, "username" => "fred"})

    sql.scan(/\bAND\b/).size.should eq 1
  end

  def test_select_condition_sql_emits_is_null_for_nil_values : Nil
    persister = build_persister

    sql = persister.select_condition_sql({"username" => nil})

    sql.should match /username\s+IS NULL/
  end

  def test_select_condition_statement_sql_emits_each_comparison_operator : Nil
    persister = build_persister

    {
      "="  => /id = \?/,
      "<>" => /id != \?/,
      ">"  => /id > \?/,
      ">=" => /id >= \?/,
      "<"  => /id < \?/,
      "<=" => /id <= \?/,
    }.each do |op, expected|
      sql = persister.select_condition_statement_sql("id", 1, comparison: op)
      sql.should match expected
    end
  end

  def test_select_condition_statement_sql_with_nin_keeps_in_then_or_null : Nil
    persister = build_persister

    sql = persister.select_condition_statement_sql("id", [1, nil, 2], comparison: "NIN")

    # NIN mirrors IN's NULL split, just with NOT IN.
    sql.should match(/\(t\d+\.id NOT IN \(\?, \?\) OR t\d+\.id IS NULL\)/)
  end

  def test_select_condition_statement_column_sql_raises_for_unknown_field : Nil
    persister = build_persister

    expect_raises(Exception, /unrecognized field/) do
      persister.select_condition_statement_sql("nonexistent_field", 1)
    end
  end

  def test_expand_parameters_passes_through_scalar_types : Nil
    persister = build_persister

    # Each scalar value becomes one positional parameter — no transformation,
    # no flattening for non-Indexable values.
    params, _types = persister.expand_parameters({
      "id"       => 42,
      "username" => "fred",
    })

    params.size.should eq 2
    params.map(&.value).includes?(42).should be_true
    params.map(&.value).includes?("fred").should be_true
  end

  def test_expand_parameters_returns_empty_for_all_nil_criteria : Nil
    persister = build_persister

    params, types = persister.expand_parameters({"id" => nil, "username" => nil})

    params.should be_empty
    types.should be_empty
  end

  def test_count_sql_with_no_criteria_omits_where_clause : Nil
    persister = build_persister

    sql = persister.count_sql(Hash(String, DB::Any).new)

    sql.should match(/^SELECT COUNT\(\*\) FROM forum_users\b/)
    sql.should_not match(/\bWHERE\b/)
  end

  def test_count_sql_with_criteria_appends_where_clause : Nil
    persister = build_persister

    sql = persister.count_sql({"username" => "fred"})

    sql.should match(/^SELECT COUNT\(\*\) FROM forum_users\b/)
    sql.should match(/\bWHERE\b/)
    sql.should match(/username = \?/)
  end

  def test_order_by_sql_returns_empty_for_empty_input : Nil
    persister = build_persister

    persister.order_by_sql(Hash(String, String).new, "t0").should eq ""
  end

  def test_order_by_sql_emits_explicit_orientation : Nil
    persister = build_persister

    persister.order_by_sql({"username" => "DESC"}, "t0").should eq " ORDER BY t0.username DESC"
    persister.order_by_sql({"username" => "ASC"}, "t0").should eq " ORDER BY t0.username ASC"
  end

  def test_order_by_sql_normalizes_lowercase_orientation : Nil
    persister = build_persister

    persister.order_by_sql({"username" => "desc"}, "t0").should eq " ORDER BY t0.username DESC"
  end

  def test_order_by_sql_joins_multiple_entries_with_comma : Nil
    persister = build_persister

    sql = persister.order_by_sql({"username" => "ASC", "id" => "DESC"}, "t0")

    sql.should eq " ORDER BY t0.username ASC, t0.id DESC"
  end

  def test_order_by_sql_expands_to_one_to_owning_side_join_columns : Nil
    persister = build_persister

    # ForumUser.avatar is the ToOne owning side; its join column is `avatar_id`.
    sql = persister.order_by_sql({"avatar" => "ASC"}, "t0")

    sql.should eq " ORDER BY t0.avatar_id ASC"
  end

  def test_order_by_sql_raises_on_invalid_orientation : Nil
    persister = build_persister

    expect_raises(Exception, /Invalid ORDER BY orientation/) do
      persister.order_by_sql({"username" => "SIDEWAYS"}, "t0")
    end
  end

  def test_order_by_sql_raises_on_unrecognized_field : Nil
    persister = build_persister

    expect_raises(Exception, /Unrecognized field/) do
      persister.order_by_sql({"nonexistent" => "ASC"}, "t0")
    end
  end

  # SELECT shape: bare query against the persister's class without criteria.
  # Output is a single-table SELECT with the entity's quoted table name and a generated alias.
  def test_select_sql_emits_select_from_with_table_alias : Nil
    persister = build_persister

    sql = persister.select_sql(Hash(String, DB::Any).new)

    sql.should match(/^SELECT .+ FROM forum_users t\d+/)
  end

  # Criteria appended to SELECT route through select_condition_sql to produce a WHERE clause with placeholders.
  def test_select_sql_appends_where_clause_when_criteria_present : Nil
    persister = build_persister

    sql = persister.select_sql({"username" => "fred".as(DB::Any)})

    sql.should match(/\bWHERE\b/)
    sql.should match(/username = \?/)
  end

  def test_insert_column_list_excludes_unmapped_instance_variables : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(UnmappedPropertyItem)

    persister.insert_column_list.should eq ["id", "name"]
  end

  # Selected columns are converted from their database representation, and bound values to it.
  def test_select_sql_converts_columns_and_parameters_through_their_type : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(SqlConvertedItem)

    sql = persister.select_sql({"name" => "fred".as(DB::Any)})

    sql.should match(/LOWER\(t\d+\.name\) AS /)
    sql.should match(/name = UPPER\(\?\)/)
  end

  # ORDER BY arg flows into order_by_sql, which uses the table alias the persister already chose.
  def test_select_sql_appends_order_by_when_present : Nil
    persister = build_persister

    sql = persister.select_sql(Hash(String, DB::Any).new, order_by: {"username" => "ASC"})

    sql.should match(/ORDER BY t\d+\.username ASC/)
  end

  # ORDER BY must come AFTER the WHERE clause when both are present, so the splice point in the generated SQL is correct.
  def test_select_sql_orders_after_where_clause : Nil
    persister = build_persister

    sql = persister.select_sql({"username" => "fred".as(DB::Any)}, order_by: {"username" => "DESC"})

    sql.index(" WHERE ").not_nil!.should be < sql.index(" ORDER BY ").not_nil!
  end

  # No order_by argument means no ORDER BY clause — empty string spliced in cleanly.
  def test_select_sql_omits_order_by_when_not_provided : Nil
    persister = build_persister

    sql = persister.select_sql(Hash(String, DB::Any).new)

    sql.should_not match(/\bORDER BY\b/)
  end

  # The persister selects every mapped field as `<alias>.<col> AS <result_alias>`, plus one entry per ToOne owning-side join column for hydrator meta-results.
  def test_select_columns_sql_lists_field_and_to_one_fk_columns : Nil
    persister = build_persister

    sql = persister.select_columns_sql

    sql.should match(/t\d+\.username AS \w+/)
    sql.should match(/t\d+\.avatar_id AS \w+/)
  end

  # `select_column_association_sql` is the FK-emitting helper for ToOne owning sides.
  # It registers each join column as a meta-result on the RSM and returns `<alias>.<col> AS <result_alias>`.
  def test_select_column_association_sql_emits_fk_for_to_one_owning : Nil
    persister = build_persister
    cm = persister.@em.class_metadata ForumUser
    assoc = cm.association_mappings["avatar"].not_nil!

    sql = persister.select_column_association_sql("avatar", assoc, cm)

    sql.should match(/t\d+\.avatar_id AS \w+/)
  end

  # ToMany associations have no FK column on the owner's table, so the helper returns an empty string.
  def test_select_column_association_sql_returns_empty_for_to_many : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CmsUser)
    cm = em.class_metadata CmsUser
    assoc = cm.association_mappings["groups"].not_nil!

    persister.select_column_association_sql("groups", assoc, cm).should eq ""
  end

  # ManyToMany loads emit an INNER JOIN against the join table on the owner's PK to the join table's inverse-side FK column.
  def test_select_many_to_many_join_sql_emits_inner_join_clause : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CmsUser)
    cm = em.class_metadata CmsUser
    assoc = cm.association_mappings["groups"].not_nil!.as AORM::Mapping::ManyToMany

    sql = persister.select_many_to_many_join_sql assoc

    sql.should start_with " INNER JOIN "
    sql.should match(/\bON\b/)
    sql.should match(/t\d+\.\w+ = \w+\.\w+/)
  end

  # `sql_table_alias` is keyed by entity_class + assoc_name; repeated calls for the same key return the cached alias rather than minting a fresh one.
  def test_sql_table_alias_caches_per_entity : Nil
    persister = build_persister

    first = persister.sql_table_alias ForumUser
    second = persister.sql_table_alias ForumUser

    first.should match(/^t\d+$/)
    first.should eq second
  end

  # Distinct entity classes get distinct aliases so multi-table SELECTs don't collide.
  def test_sql_table_alias_yields_distinct_aliases_for_different_entities : Nil
    persister = build_persister

    forum_alias = persister.sql_table_alias ForumUser
    avatar_alias = persister.sql_table_alias ForumAvatar

    forum_alias.should_not eq avatar_alias
  end

  # `sql_column_alias` rendering is delegated to the quote strategy; it must always return a non-empty identifier safe to splice into SQL.
  def test_sql_column_alias_returns_non_empty_identifier : Nil
    persister = build_persister

    alias_name = persister.sql_column_alias("username")

    alias_name.should_not be_empty
    alias_name.should match(/^\w+$/)
  end

  # Filtering by a ManyToMany association field is not supported on the persister side.
  def test_select_condition_statement_sql_raises_for_many_to_many_field : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CmsUser)

    user = CmsUser.new
    user.username = "fred"

    expect_raises(Exception, /ManyToMany/) do
      persister.select_condition_statement_sql("groups", user)
    end
  end

  # Filtering by an inverse-side OneToMany must redirect to the owning side; the persister refuses to guess.
  def test_select_condition_statement_sql_raises_for_inverse_side_field : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(TagOwnerWithTags)

    tag = OwnedTag.new

    expect_raises(Exception, /inverse side/) do
      persister.select_condition_statement_sql("tags", tag)
    end
  end

  # Composite-PK ORDER BY: each PK component gets its own clause separated by commas, alphabetized by the input hash's order.
  def test_order_by_sql_renders_composite_identifier_fields : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CompositePkItem)

    sql = persister.order_by_sql({"tenant_id" => "ASC", "item_id" => "DESC"}, "t0")

    sql.should eq " ORDER BY t0.tenant_id ASC, t0.item_id DESC"
  end

  def test_execute_inserts_appends_returning_clause_on_supporting_platform : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CompositeAutoItem)

    item = CompositeAutoItem.new
    item.label = "widget"

    em.unit_of_work.persist item
    persister.add_insert item
    persister.execute_inserts

    insert_sql = connection.built_statements.last
    insert_sql.should match(/INSERT INTO\s+composite_auto_items\b/)
    insert_sql.should match(/\bRETURNING\s+tenant_id,\s*item_id\b/)
    item.tenant_id.should eq 1_i64
    item.item_id.should eq 1_i64
  end

  def test_execute_inserts_emits_plain_insert_on_non_returning_platform : Nil
    connection = MockConnection.new driver_name: "mysql", server_name: "MySQL"
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(ForumUser)

    avatar = ForumAvatar.new
    em.unit_of_work.register_managed avatar, {"id" => 99}, {"id" => 99}

    user = ForumUser.new
    user.username = "fred"
    user.avatar = avatar

    connection.push_ids 42

    em.unit_of_work.persist user
    persister.add_insert user
    persister.execute_inserts

    insert_sql = connection.built_statements.last
    insert_sql.should match(/INSERT INTO\s+forum_users\b/)
    insert_sql.should_not match(/\bRETURNING\b/)
    user.id.should eq 42
  end

  # The WHERE clause must target identifier columns, not identifier field names.
  def test_delete_conditions_on_identifier_column_names : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(RenamedPkItem)

    item = RenamedPkItem.new
    item.id = 7
    em.unit_of_work.register_managed item, {"id" => 7}, {"id" => 7}

    persister.delete(item).should be_true

    connection.built_statements.last.should eq "DELETE FROM renamed_pk_items WHERE item_pk = ?"
  end

  # The inverse side's rows are deleted through the owning side's inverse join columns, and a self-referencing association's rows through its other join columns too.
  def test_delete_removes_many_to_many_join_table_rows : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(JoinRowsParent)

    friend = JoinRowsParent.new
    friend.id = 2
    parent = JoinRowsParent.new
    parent.id = 1
    parent.my_friends << friend

    em.unit_of_work.register_managed parent, {"id" => 1}, {"id" => 1}
    em.unit_of_work.register_managed friend, {"id" => 2}, {"id" => 2}

    persister.delete parent

    connection.executed_statements[0, 2].should eq [
      {"DELETE FROM customtype_parent_friends WHERE friend_customtypeparent_id = ?", [1]},
      {"DELETE FROM customtype_parent_friends WHERE customtypeparent_id = ?", [1]},
    ]
  end

  # Default join columns are `ON DELETE CASCADE`, so the database deletes the rows instead.
  def test_delete_leaves_join_table_rows_of_default_join_columns_to_the_database : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(DefaultJoinRowsOwner)

    owner = DefaultJoinRowsOwner.new
    owner.id = 1
    em.unit_of_work.register_managed owner, {"id" => 1}, {"id" => 1}

    persister.delete owner

    connection.executed_statements.should eq [{"DELETE FROM default_join_rows_owners WHERE id = ?", [1]}]
  end

  def test_execute_inserts_binds_values_converted_through_their_mapped_types : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    item = Rot13Item.new
    item.id = "abc"
    item.secret = "hello"

    em.unit_of_work.persist item
    em.unit_of_work.compute_changesets
    persister.add_insert item
    persister.execute_inserts

    connection.executed_statements.last.should eq({"INSERT INTO rot13_items (id, secret) VALUES (?, ?)", ["nop", "uryyb"]})
  end

  # Columns hold UTC wall-clock time, so a time in another location must reach the driver already shifted to UTC.
  def test_execute_inserts_binds_datetime_values_in_utc : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(TimestampedItem)

    item = TimestampedItem.new
    item.id = 1
    item.created_at = Time.local 2016, 1, 1, 15, 58, 59, location: Time::Location.fixed(-5 * 3600)

    em.unit_of_work.persist item
    em.unit_of_work.compute_changesets
    persister.add_insert item
    persister.execute_inserts

    bound_time = connection.executed_statements.last[1][1].as(Time)
    bound_time.utc?.should be_true
    bound_time.should eq Time.utc(2016, 1, 1, 20, 58, 59)
  end

  def test_update_binds_values_and_identifier_converted_through_their_mapped_types : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    item = Rot13Item.new
    item.id = "abc"
    item.secret = "hello"
    em.unit_of_work.register_managed item, {"id" => "abc"}, {"id" => "abc", "secret" => "hello"}

    item.secret = "world"
    em.unit_of_work.compute_changesets
    persister.update item

    connection.executed_statements.last.should eq({"UPDATE rot13_items SET secret = ? WHERE id = ?", ["jbeyq", "nop"]})
  end

  def test_delete_binds_identifier_converted_through_its_mapped_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    item = Rot13Item.new
    item.id = "abc"
    em.unit_of_work.register_managed item, {"id" => "abc"}, {"id" => "abc"}

    persister.delete item

    connection.executed_statements.last.should eq({"DELETE FROM rot13_items WHERE id = ?", ["nop"]})
  end

  def test_expand_parameters_returns_the_mapped_type_of_each_field : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    params, types = persister.expand_parameters({"secret" => "hello"})

    params.map(&.value).should eq ["hello"]
    types.should eq ["rot13"]
  end

  # Association criteria bind the target's identifier, so they take the type of the column the foreign key references.
  def test_expand_parameters_types_associations_by_the_referenced_column : Nil
    persister = build_persister

    avatar = ForumAvatar.new
    persister.@em.unit_of_work.register_managed avatar, {"id" => 99}, {"id" => 99}

    params, types = persister.expand_parameters({"avatar" => avatar})

    params.map(&.value).should eq [99]
    types.should eq ["integer"]
  end

  def test_expand_parameters_types_each_in_list_element : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    params, types = persister.expand_parameters({"secret" => ["a", nil, "b"]})

    params.map(&.value).should eq ["a", "b"]
    types.should eq ["rot13", "rot13"]
  end

  def test_load_binds_criteria_converted_through_their_mapped_types : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    connection.queue_result [] of Hash(String, DB::Any)
    persister.load({"secret" => "hello"})

    connection.executed_statements.last[1].should eq ["uryyb"]
  end

  def test_load_all_binds_each_in_list_element_converted_through_the_field_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    connection.queue_result [] of Hash(String, DB::Any)
    persister.load_all({"secret" => ["hello", "world"]})

    connection.executed_statements.last[1].should eq ["uryyb", "jbeyq"]
  end

  def test_count_binds_criteria_converted_through_their_mapped_types : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    connection.queue_result [{"count" => 3_i64} of String => DB::Any]

    persister.count({"secret" => "hello"}).should eq 3
    connection.executed_statements.last[1].should eq ["uryyb"]
  end

  def test_exists_binds_the_identifier_converted_through_its_mapped_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    item = Rot13Item.new
    item.id = "abc"

    connection.queue_result [{"1" => 1} of String => DB::Any]

    persister.exists(item).should be_true
    connection.executed_statements.last[1].should eq ["nop"]
  end

  def test_exists_is_false_without_a_matching_row : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(Rot13Item)

    item = Rot13Item.new
    item.id = "abc"

    connection.queue_result [] of Hash(String, DB::Any)

    persister.exists(item).should be_false
  end

  def test_load_one_to_many_collection_binds_the_owner_identifier_converted_through_its_mapped_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(ValueConversionType::OwningManyToOneEntity)
    assoc = em.class_metadata(ValueConversionType::InversedOneToManyEntity).association_mappings["associated_entities"].as(AORM::Mapping::OneToMany)

    owner = ValueConversionType::InversedOneToManyEntity.new
    owner.id1 = "abc"
    em.unit_of_work.register_managed owner, {"id1" => "abc"}, {"id1" => "abc"}

    collection = AORM::PersistentCollection(ValueConversionType::OwningManyToOneEntity).new
    collection.set_owner owner, assoc

    connection.queue_result [] of Hash(String, DB::Any)
    persister.load_one_to_many_collection assoc, owner, collection

    connection.executed_statements.last[1].should eq ["nop"]
  end

  def test_load_many_to_many_collection_binds_the_owner_identifier_converted_through_its_mapped_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(ValueConversionType::InversedManyToManyEntity)
    assoc = em.class_metadata(ValueConversionType::OwningManyToManyEntity).association_mappings["associated_entities"].as(AORM::Mapping::ManyToMany)

    owner = ValueConversionType::OwningManyToManyEntity.new
    owner.id2 = "abc"
    em.unit_of_work.register_managed owner, {"id2" => "abc"}, {"id2" => "abc"}

    collection = AORM::PersistentCollection(ValueConversionType::InversedManyToManyEntity).new
    collection.set_owner owner, assoc

    connection.queue_result [] of Hash(String, DB::Any)
    persister.load_many_to_many_collection assoc, owner, collection

    connection.executed_statements.last[1].should eq ["nop"]
  end

  def test_execute_inserts_binds_value_object_fields_converted_through_their_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CustomIdObjectTypeParent)

    parent = CustomIdObjectTypeParent.new
    parent.id = CustomIdObject.new "abc"
    parent.other_id = CustomIdObject.new "def"

    em.unit_of_work.persist parent
    em.unit_of_work.compute_changesets
    persister.add_insert parent
    persister.execute_inserts

    connection.executed_statements.last.should eq({"INSERT INTO custom_id_type_parent (id, other_id) VALUES (?, ?)", ["abc", "def"]})
  end

  def test_execute_inserts_reads_back_a_generated_value_object_identifier : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CustomIdObjectTypeGenerated)

    item = CustomIdObjectTypeGenerated.new
    item.name = "widget"

    em.unit_of_work.persist item
    em.unit_of_work.compute_changesets
    persister.add_insert item

    connection.queue_result [{"id" => "generated"} of String => DB::Any]
    persister.execute_inserts

    item.id.should eq CustomIdObject.new("generated")
  end

  def test_update_binds_value_object_field_and_identifier_converted_through_their_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CustomIdObjectTypeParent)

    parent = CustomIdObjectTypeParent.new
    parent.id = CustomIdObject.new "abc"
    parent.other_id = CustomIdObject.new "def"
    em.unit_of_work.register_managed parent, {"id" => parent.id}, {"id" => parent.id, "other_id" => parent.other_id}

    parent.other_id = CustomIdObject.new "xyz"
    em.unit_of_work.compute_changesets
    persister.update parent

    connection.executed_statements.last.should eq({"UPDATE custom_id_type_parent SET other_id = ? WHERE id = ?", ["xyz", "abc"]})
  end

  def test_delete_binds_value_object_identifier_converted_through_its_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CustomIdObjectTypeParent)

    parent = CustomIdObjectTypeParent.new
    parent.id = CustomIdObject.new "abc"
    em.unit_of_work.register_managed parent, {"id" => parent.id}, {"id" => parent.id}

    persister.delete parent

    connection.executed_statements.last.should eq({"DELETE FROM custom_id_type_parent WHERE id = ?", ["abc"]})
  end

  def test_load_binds_value_object_criteria_converted_through_their_type : Nil
    connection = MockConnection.new
    em = MockEntityManager.new(connection)
    persister = AORM::Persisters::Entity::Basic.new em, em.class_metadata(CustomIdObjectTypeParent)

    connection.queue_result [] of Hash(String, DB::Any)
    persister.load({"other_id" => CustomIdObject.new("def")})

    connection.executed_statements.last[1].should eq ["def"]
  end

  private def build_persister : AORM::Persisters::Entity::Basic
    em = MockEntityManager.new(MockConnection.new)
    AORM::Persisters::Entity::Basic.new em, em.class_metadata(ForumUser)
  end
end
