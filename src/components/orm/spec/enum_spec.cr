require "./spec_helper"

struct EnumTest < ASPEC::TestCase
  @connection : MockConnection
  @em : MockEntityManager

  def initialize
    @connection = MockConnection.new
    @em = MockEntityManager.new @connection
  end

  # ===== Mapping =====

  def test_enum_field_maps_to_its_integer_backing_type : Nil
    field = @em.class_metadata(Card).field_mappings["suit"]

    field.type.should eq "integer"
    field.enum_type.should eq "Suit"
  end

  def test_enum_with_a_64_bit_base_type_maps_to_bigint : Nil
    @em.class_metadata(Ticket).field_mappings["priority"].type.should eq "bigint"
  end

  def test_enum_with_a_narrow_base_type_maps_to_integer : Nil
    @em.class_metadata(Ticket).field_mappings["permissions"].type.should eq "integer"
  end

  def test_enum_field_rejects_a_non_integer_type : Nil
    expect_raises(Exception, /Enum field 'suit' on CardWithStringSuit must be mapped to an integer type, got 'string'/) do
      @em.class_metadata CardWithStringSuit
    end
  end

  # ===== Field access =====

  def test_reading_an_enum_field_returns_its_stored_integer : Nil
    card = Card.new
    card.suit = Suit::Spades

    @em.class_metadata(Card).get_field_value(card, "suit").should eq 3
  end

  def test_writing_an_enum_field_accepts_its_stored_integer : Nil
    card = Card.new

    @em.class_metadata(Card).set_field_value card, "suit", 1

    card.suit.should eq Suit::Diamonds
  end

  # ===== Writes =====

  def test_inserting_binds_the_enum_integer : Nil
    card = Card.new
    card.id = 1
    card.suit = Suit::Spades

    self.insert card

    @connection.executed_statements.last.should eq({"INSERT INTO cards (id, suit) VALUES (?, ?)", [1, 3]})
  end

  def test_inserting_binds_null_for_a_nil_enum : Nil
    card = CardWithNullable.new
    card.id = 1

    self.insert card

    @connection.executed_statements.last[1].should eq [1, nil]
  end

  # Flags combine their members' bits into a single stored integer.
  def test_inserting_binds_combined_flags_and_wide_enum_values : Nil
    ticket = Ticket.new
    ticket.id = 1
    ticket.permissions = Permission::Read | Permission::Write
    ticket.priority = Priority::High

    self.insert ticket

    @connection.executed_statements.last[1].should eq [1, 3, 5_000_000_000_i64]
  end

  def test_changing_an_enum_field_binds_the_new_integer : Nil
    card = self.managed_card Suit::Hearts
    card.suit = Suit::Spades

    @em.unit_of_work.compute_changesets
    AORM::Persisters::Entity::Basic.new(@em, @em.class_metadata(Card)).update card

    @connection.executed_statements.last.should eq({"UPDATE cards SET suit = ? WHERE id = ?", [3, 1]})
  end

  def test_unchanged_enum_field_produces_no_change_set : Nil
    card = self.managed_card Suit::Hearts

    @em.unit_of_work.compute_changesets

    @em.unit_of_work.entity_changeset(card).should be_empty
    @em.unit_of_work.scheduled_entity_updates.should be_empty
  end

  def test_deleting_by_an_enum_identifier_binds_the_enum_integer : Nil
    card = CardWithEnumId.new
    card.suit = Suit::Clubs
    @em.unit_of_work.register_managed card, {"suit" => Suit::Clubs}, {"suit" => Suit::Clubs}

    AORM::Persisters::Entity::Basic.new(@em, @em.class_metadata(CardWithEnumId)).delete card

    @connection.executed_statements.last.should eq({"DELETE FROM cards_with_enum_id WHERE suit = ?", [2]})
  end

  # ===== Queries =====

  def test_find_by_enum_binds_the_enum_integer : Nil
    @connection.queue_result [] of Hash(String, DB::Any)

    @em.repository(Card).find_by suit: Suit::Spades

    @connection.executed_statements.last[1].should eq [3]
  end

  # ===== Hydration =====

  def test_enum_hydration : Nil
    rs = FakeResultSet.new([{"c__id" => 1.as(DB::Any), "c__suit" => 3.as(DB::Any)}])

    card = AORM::Internal::Hydrators::SimpleObject.new(@em).hydrate_all(rs, self.card_rsm(Card)).first.as(Card)

    card.suit.should eq Suit::Spades
  end

  def test_enum_hydration_object_hydrator : Nil
    rs = FakeResultSet.new([{"c__id" => 1.as(DB::Any), "c__suit" => 3.as(DB::Any)}])

    card = AORM::Internal::Hydrators::Object.new(@em).hydrate_all(rs, self.card_rsm(Card)).first.as(Card)

    card.suit.should eq Suit::Spades
  end

  def test_nullable_enum_hydration : Nil
    rs = FakeResultSet.new([{"c__id" => 1.as(DB::Any), "c__suit" => nil.as(DB::Any)}])

    card = AORM::Internal::Hydrators::SimpleObject.new(@em).hydrate_all(rs, self.card_rsm(CardWithNullable)).first.as(CardWithNullable)

    card.suit.should be_nil
  end

  def test_enum_with_non_matching_database_value_raises : Nil
    rs = FakeResultSet.new([{"c__id" => 1.as(DB::Any), "c__suit" => 42.as(DB::Any)}])

    expect_raises(ArgumentError, "Unknown enum Suit value: 42") do
      AORM::Internal::Hydrators::SimpleObject.new(@em).hydrate_all(rs, self.card_rsm(Card))
    end
  end

  def test_flags_and_wide_enum_hydration : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result Ticket, "t"
    rsm.add_field_result "t", "t__id", "id"
    rsm.add_field_result "t", "t__permissions", "permissions"
    rsm.add_field_result "t", "t__priority", "priority"

    rs = FakeResultSet.new([{"t__id" => 1.as(DB::Any), "t__permissions" => 3.as(DB::Any), "t__priority" => 5_000_000_000_i64.as(DB::Any)}])

    ticket = AORM::Internal::Hydrators::SimpleObject.new(@em).hydrate_all(rs, rsm).first.as(Ticket)

    ticket.permissions.should eq Permission::Read | Permission::Write
    ticket.priority.should eq Priority::High
  end

  # ===== Helpers =====

  private def insert(entity : AORM::Entity) : Nil
    persister = AORM::Persisters::Entity::Basic.new @em, @em.class_metadata(entity.class)

    @em.unit_of_work.persist entity
    @em.unit_of_work.compute_changesets
    persister.add_insert entity
    persister.execute_inserts
  end

  private def managed_card(suit : Suit) : Card
    card = Card.new
    card.id = 1
    card.suit = suit
    @em.unit_of_work.register_managed card, {"id" => 1}, {"id" => 1, "suit" => suit}

    card
  end

  private def card_rsm(entity_class : AORM::Entity.class) : AORM::Query::ResultSetMapping
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result entity_class, "c"
    rsm.add_field_result "c", "c__id", "id"
    rsm.add_field_result "c", "c__suit", "suit"
    rsm
  end
end
