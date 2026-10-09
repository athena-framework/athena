require "spec"
require "../src/athena-orm"
require "athena-spec"

require "./dbal_types/**"
require "./models/**"

ASPEC.run_all

# Declares the collection types the specs use besides those of entities, which the library declares itself.
# A collection type first created while the program is typed re-types every call with a block already typed through `AORM::BaseCollection`, for every collection type.
class SpecCollectionTypes
  @@array_int32 : AORM::ArrayCollection(Int32)? = nil
  @@array_string : AORM::ArrayCollection(String)? = nil
  @@persistent_int32 : AORM::PersistentCollection(Int32)? = nil
  @@persistent_string : AORM::PersistentCollection(String)? = nil
  @@persistent_entity : AORM::PersistentCollection(AORM::Entity)? = nil
end

class MockPlatform < AORM::Platforms::Platform
  setter db_boolean : Bool?
  setter crystal_boolean : Bool?

  def initialize(
    *,
    @db_boolean : Bool? = nil,
    @crystal_boolean : Bool? = nil,
  ); end

  def boolean_type_declaration_sql(column : AORM::Schema::Column) : String
    "BOOLEAN"
  end

  def small_int_type_declaration_sql(column : AORM::Schema::Column) : String
    "SMALLINT"
  end

  def blob_type_declaration_sql(column : AORM::Schema::Column) : String
    "BLOB"
  end

  def date_time_type_declaration_sql(column : AORM::Schema::Column) : String
    "DATETIME"
  end

  def integer_type_declaration_sql(column : AORM::Schema::Column) : String
    "INTEGER"
  end

  def big_int_type_declaration_sql(column : AORM::Schema::Column) : String
    "BIGINT"
  end

  private def common_integer_type_declaration_sql(column : AORM::Schema::Column) : String
    ""
  end

  def convert_booleans_to_db_value(value) : Bool?
    @db_boolean.try { |v| return v } || super
  end

  def convert_from_boolean(value) : Bool?
    @crystal_boolean.try { |v| return v } || super
  end
end

class MockUnitOfWork < AORM::UnitOfWork
  @mock_data_changesets = Hash(AORM::Entity, Hash(String, AORM::UnitOfWork::Change)).new.compare_by_identity
  @persister_mock = Hash(AORM::Entity.class, AORM::Persisters::Entity::Interface).new.compare_by_identity

  def entity_persister(entity_class : AORM::Entity.class) : AORM::Persisters::Entity::Interface
    @persister_mock[entity_class]? || super
  end

  def set_entity_persister(entity_class : AORM::Entity.class, persister : AORM::Persisters::Entity::Basic) : Nil
    @persister_mock[entity_class] = persister
  end

  # Test access to the topologically-sorted insert order.
  def insert_execution_order : Array(AORM::Entity)
    self.compute_insert_execution_order
  end

  # Test access to the protected `collection_persister`.
  def collection_persister_for(assoc : AORM::Mapping::Association)
    self.collection_persister assoc
  end

  # Test access to the private `add_to_entity_identifier_and_entity_map`.
  # The method only fires through a niche commit path (assigned ID with FK-as-identifier targets), so direct testing is the practical way to lock its behavior in.
  def expose_add_to_entity_identifier_and_entity_map(class_metadata : AORM::Mapping::ClassInterface, entity : AORM::Entity) : Nil
    self.add_to_entity_identifier_and_entity_map class_metadata, entity
  end
end

class MockEntityManager < AORM::EntityManager
  setter uow_mock : AORM::UnitOfWork? = nil

  def initialize(connection : DB::Connection)
    # TODO: Setup config?
    super connection
  end

  def initialize(connection : DB::Connection, event_dispatcher : ACTR::EventDispatcher::Interface)
    super connection, event_dispatcher
  end

  def unit_of_work : AORM::UnitOfWork
    @uow_mock || super
  end
end

class MockEntityPersister < AORM::Persisters::Entity::Basic
  record PostInsert, generated_id : Int32, entity : AORM::Entity

  # Test access to the protected `prepare_insert_data`.
  def insert_data_for(entity : AORM::Entity) : Hash(String, Hash(String, AORM::Mapping::Value))
    self.prepare_insert_data entity
  end

  # Test access to the protected `prepare_update_data`.
  def update_data_for(entity : AORM::Entity) : Hash(String, Hash(String, AORM::Mapping::Value))
    self.prepare_update_data entity
  end

  getter execute_insert_call_count : Int32 = 0
  getter inserts : Array(AORM::Entity) = [] of AORM::Entity
  getter updates : Array(AORM::Entity) = [] of AORM::Entity
  getter deletes : Array(AORM::Entity) = [] of AORM::Entity

  # The data each insert and update would write, captured when the unit of work hands the entity over.
  getter insert_data : Array(Hash(String, Hash(String, AORM::Mapping::Value))) = [] of Hash(String, Hash(String, AORM::Mapping::Value))
  getter update_data : Array(Hash(String, Hash(String, AORM::Mapping::Value))) = [] of Hash(String, Hash(String, AORM::Mapping::Value))
  setter mock_id_generator : AORM::Mapping::GeneratedValueStrategy? = nil
  getter? exists_called : Bool = false
  property mock_exists_result : Bool = false

  @post_insert_ids = Array(PostInsert).new
  @identity_column_counter : Int32 = 0

  def add_insert(entity : AORM::Entity) : Nil
    @inserts << entity
    @insert_data << self.prepare_insert_data entity

    if !@mock_id_generator.try(&.identity?) && !@class_metadata.identifier_identity?
      return
    end

    id = @identity_column_counter += 1
    @post_insert_ids << PostInsert.new id, entity
  end

  def execute_inserts : Nil
    @execute_insert_call_count += 1

    @post_insert_ids.each do |pi|
      id_field = @class_metadata.single_identifier_field_name
      id_hash = {id_field => AORM::Mapping::SingleValue.new(pi.generated_id.as(::DB::Any)).as(AORM::Mapping::Value)}
      @em.unit_of_work.assign_post_insert_id pi.entity, id_hash
    end
  end

  def update(entity : AORM::Entity) : Nil
    @updates << entity
    @update_data << self.prepare_update_data entity
  end

  def exists(entity : AORM::Entity, extra_conditions = nil) : Bool
    @exists_called = true
    @mock_exists_result
  end

  def delete(entity : AORM::Entity) : Bool
    @deletes << entity

    true
  end

  # Test fixture: canned entity returned by `load_by_id`. Setting it overrides
  # the real DB-fetching behavior so repo / find tests can exercise the
  # delegation path without standing up a real result set.
  setter mock_load_by_id_result : AORM::Entity? = nil
  getter load_by_id_calls : Array(Hash(String, Int32 | Int64 | String)) = [] of Hash(String, Int32 | Int64 | String)

  # Test fixture: canned entity returned by `load`. Captures every call's
  # criteria and limit so specs can assert what the repository forwarded.
  setter mock_load_result : AORM::Entity? = nil
  alias LoadCallValue = AORM::Mapping::ValueAny | AORM::Entity | Array(Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil)
  record LoadCall, criteria : Hash(String, LoadCallValue), limit : Int32?
  getter load_calls : Array(LoadCall) = [] of LoadCall

  # Test fixture: canned array returned by `load_all`. Captures criteria,
  # order_by, limit, and offset so specs can assert the repo's forwarding.
  setter mock_load_all_result : Array(AORM::Entity) = [] of AORM::Entity
  record LoadAllCall,
    criteria : Hash(String, Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil | Array(Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil)),
    order_by : Hash(String, String)?,
    limit : Int32?,
    offset : Int32?
  getter load_all_calls : Array(LoadAllCall) = [] of LoadAllCall

  def load_by_id(id : Hash(String, Int | String)) : AORM::Entity?
    widened = id.transform_values { |v| v.is_a?(Int) ? v.to_i64.as(Int32 | Int64 | String) : v.as(Int32 | Int64 | String) }
    @load_by_id_calls << widened
    @mock_load_by_id_result
  end

  # Test fixture: when set, `load` simulates a fresh row by calling
  # `uow.create_entity` with this data, which runs the refresh-hint code path
  # for already-managed entities. Used for `UoW#refresh` specs.
  setter mock_refresh_data : Hash(String, DB::Any)? = nil

  # Test fixture: when set, `load` hydrates this data through `uow.create_entity`, registering the entity as managed like a real load does.
  setter mock_load_data : Hash(String, DB::Any)? = nil

  def load(
    criteria : Hash(String, _),
    entity : AORM::Entity? = nil,
    association : AORM::Mapping::Association? = nil,
    hints : AORM::Query::Hints = AORM::Query::Hints.new,
    lock_mode : AORM::LockMode? = nil,
    limit : Int? = nil,
    order_by : Hash(String, String)? = nil,
  ) : AORM::Entity?
    widened_criteria = Hash(String, LoadCallValue).new
    criteria.each { |k, v| widened_criteria[k] = v.as(LoadCallValue) }
    @load_calls << LoadCall.new(widened_criteria, limit.try(&.to_i32))

    if (data = @mock_refresh_data) && hints.refresh? && entity
      @em.unit_of_work.create_entity entity.class, data, hints
      return entity
    end

    if data = @mock_load_data
      return @em.unit_of_work.create_entity @class_metadata.entity_class, data
    end

    @mock_load_result
  end

  def load_all(
    criteria : Hash(String, _) = Hash(String, DB::Any).new,
    order_by : Hash(String, String)? = nil,
    limit : Int? = nil,
    offset : Int32? = nil,
  ) : Array(AORM::Entity)
    @load_all_calls << LoadAllCall.new(
      criteria.transform_values { |v| v.as(DB::Any | Array(DB::Any)) },
      order_by,
      limit.try(&.to_i32),
      offset
    )
    @mock_load_all_result
  end

  # Test fixture: canned count returned by `count`. Captures the criteria so
  # specs can assert what the repository forwarded.
  setter mock_count_result : Int32 = 0
  getter count_calls : Array(Hash(String, Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil | Array(Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil))) = [] of Hash(String, Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil | Array(Bool | Float32 | Float64 | Int32 | Int64 | Slice(UInt8) | String | Time | Nil))

  def count(criteria : Hash(String, _) = Hash(String, DB::Any).new) : Int32
    @count_calls << criteria.transform_values { |v| v.as(DB::Any | Array(DB::Any)) }
    @mock_count_result
  end

  def reset : Nil
    @execute_insert_call_count = 0
    @exists_called = false
    @identity_column_counter = 0
    @inserts.clear
    @updates.clear
    @deletes.clear
    @load_by_id_calls.clear
    @load_calls.clear
    @load_all_calls.clear
    @count_calls.clear
  end
end

class MockStatement < DB::Statement
  def perform_query(args : Enumerable) : DB::ResultSet
    self.record_execution args
    connection.as(MockConnection).next_result_set || MockResultSet.new(self)
  end

  # Only an `INSERT` generates an identifier, as with a real database.
  def perform_exec(args : Enumerable) : DB::ExecResult
    self.record_execution args
    ::DB::ExecResult.new(
      rows_affected: 1,
      last_insert_id: command.lstrip.upcase.starts_with?("INSERT") ? connection.as(MockConnection).next_insert_id : 0_i64
    )
  end

  private def record_execution(args : Enumerable) : Nil
    bound = [] of DB::Any
    args.each { |arg| bound << arg.as(DB::Any) }
    connection.as(MockConnection).executed_statements << {command, bound}
  end
end

class MockConnection < DB::Connection
  # The driver shard the connection claims to be from, which determines its `AORM::Driver`.
  property driver_name : String = "sqlite3"

  property server_name : String? = nil

  @insert_ids = Deque(Int64).new

  getter built_statements : Array(String) = [] of String

  # Every executed statement's SQL with the arguments bound to it, in execution order.
  getter executed_statements : Array({String, Array(DB::Any)}) = [] of {String, Array(DB::Any)}

  @queued_results = Deque(Array(Hash(String, DB::Any))).new

  # Queues the rows returned by the next executed query.
  # Queries with nothing queued fall back to `MockResultSet`.
  def queue_result(rows : Array(Hash(String, DB::Any))) : Nil
    @queued_results << rows
  end

  def next_result_set : DB::ResultSet?
    @queued_results.shift?.try { |rows| FakeResultSet.new rows }
  end

  def self.new(driver_name : String = "sqlite3", server_name : String? = nil)
    connection = new DB::Connection::Options.new
    connection.driver_name = driver_name
    connection.server_name = server_name
    connection
  end

  def build_prepared_statement(query) : DB::Statement
    @built_statements << query
    MockStatement.new self, query
  end

  def build_unprepared_statement(query) : DB::Statement
    @built_statements << query
    MockStatement.new self, query
  end

  # Queues the identifiers the next executed `INSERT` statements report, in order.
  def push_ids(*ids : Int) : Nil
    ids.each { |id| @insert_ids << id.to_i64 }
  end

  # The identifier the next executed `INSERT` reports, `0` (none generated) when none is queued.
  def next_insert_id : Int64
    @insert_ids.shift? || 0_i64
  end
end

# Result set that yields a fixed list of `Hash(String, DB::Any)` rows.
# Implements just enough of `DB::ResultSet` for hydrator code paths (`column_names`, `each`, `read`, `move_next`, `close`). Use this when a spec needs to drive hydration end-to-end with deterministic row data.
class FakeResultSet < DB::ResultSet
  def initialize(@rows : Array(Hash(String, DB::Any)))
    statement = MockStatement.new(MockConnection.new, "")
    super(statement)
    @row_idx = -1
    @col_idx = 0
    @columns = @rows.empty? ? [] of String : @rows.first.keys
  end

  def move_next : Bool
    @row_idx += 1
    @col_idx = 0
    @row_idx < @rows.size
  end

  def column_count : Int32
    @columns.size
  end

  def column_name(index : Int32) : String
    @columns[index]
  end

  def read
    val = @rows[@row_idx][@columns[@col_idx]]
    @col_idx += 1
    val
  end

  def next_column_index : Int32
    @col_idx
  end
end

class MockResultSet < DB::ResultSet
  def move_next : Bool
    true
  end

  def column_count : Int32
    0
  end

  def column_name(index : Int32) : String
    "id"
  end

  def read
    1_i64
  end

  def next_column_index : Int32
    0
  end
end

abstract struct ORMTestCase
  protected def test_entity_manager : MockEntityManager
    self.create_test_entity_manager_with_platform Platforms::SQLite.new
  end

  protected def create_test_entity_manager_with_platform(platform : Platforms::Platform) : MockEntityManager
    self.build_test_entity_manager_with_platform(
      self.create_connection_mock(platform)
    )
  end

  private def build_test_entity_manager_with_platform(connection : DB::Connection) : MockEntityManager
  end

  private def create_connection_mock(platform : Platforms::Platform) : MockConnection
    MockConnection.new
  end
end
