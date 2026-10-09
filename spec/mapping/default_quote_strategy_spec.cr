require "../spec_helper"

@[AORMA::Entity]
@[AORMA::Table(name: "non_reserved")]
class QuoteStrategyTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "`reserved`")]
class QuoteStrategyQuotedTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "custom.non_reserved")]
class QuoteStrategySchemaTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "custom.`reserved`")]
class QuoteStrategyQuotedSchemaTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "non_reserved", schema: "custom")]
class QuoteStrategySchemaArgumentTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
class QuoteStrategyJoinTableTarget < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
class QuoteStrategyJoinTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "plain_join")]
  property plain : AORM::Collection(QuoteStrategyJoinTableTarget) = AORM::ArrayCollection(QuoteStrategyJoinTableTarget).new

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "`quoted_join`")]
  property quoted : AORM::Collection(QuoteStrategyJoinTableTarget) = AORM::ArrayCollection(QuoteStrategyJoinTableTarget).new

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "author_reader", schema: "readers")]
  property with_schema : AORM::Collection(QuoteStrategyJoinTableTarget) = AORM::ArrayCollection(QuoteStrategyJoinTableTarget).new
end

private def load(entity_class : T.class) : AORM::Mapping::Class(T) forall T
  metadata = AORM::Mapping::Class(T).new
  AORM::Mapping::Driver::Annotation.new.load_metadata_for_entity metadata
  metadata
end

struct DefaultQuoteStrategyTest < ASPEC::TestCase
  @strategy = AORM::Mapping::DefaultQuoteStrategy.new
  @platform = AORM::Platforms::SQLite.new

  def test_table_name : Nil
    @strategy.table_name(load(QuoteStrategyTableFixture), @platform).should eq "non_reserved"
  end

  def test_quoted_table_name : Nil
    @strategy.table_name(load(QuoteStrategyQuotedTableFixture), @platform).should eq %("reserved")
  end

  def test_table_name_with_schema : Nil
    @strategy.table_name(load(QuoteStrategySchemaTableFixture), @platform).should eq "custom.non_reserved"
  end

  # A quoted table's schema is quoted as well.
  def test_quoted_table_name_with_schema : Nil
    @strategy.table_name(load(QuoteStrategyQuotedSchemaTableFixture), @platform).should eq %("custom"."reserved")
  end

  def test_table_name_with_schema_argument : Nil
    @strategy.table_name(load(QuoteStrategySchemaArgumentTableFixture), @platform).should eq "custom.non_reserved"
  end

  def test_join_table_name : Nil
    metadata = load QuoteStrategyJoinTableFixture
    assoc = metadata.association_mappings["plain"].as AORM::Mapping::ManyToManyOwningSide

    @strategy.join_table_name(assoc, metadata, @platform).should eq "plain_join"
  end

  def test_quoted_join_table_name : Nil
    metadata = load QuoteStrategyJoinTableFixture
    assoc = metadata.association_mappings["quoted"].as AORM::Mapping::ManyToManyOwningSide

    @strategy.join_table_name(assoc, metadata, @platform).should eq %("quoted_join")
  end

  def test_join_table_name_with_schema : Nil
    metadata = load QuoteStrategyJoinTableFixture
    assoc = metadata.association_mappings["with_schema"].as AORM::Mapping::ManyToManyOwningSide

    @strategy.join_table_name(assoc, metadata, @platform).should eq "readers.author_reader"
  end
end
