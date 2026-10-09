# Executes a native SQL query, hydrating the rows it returns into entities as described by a `Query::ResultSetMapping`.
#
# Native queries cover what the `AORM::EntityRepository` finders can't express, such as joins, subqueries, or vendor-specific SQL.
# The SQL is executed as written, so it is only as portable between database platforms as the SQL itself.
# They are created via `AORM::EntityManager#create_native_query`:
#
# ```
# rsm = AORM::Query::ResultSetMapping.new
# rsm.add_entity_result User, "u"
# rsm.add_field_result "u", "id", "id"
# rsm.add_field_result "u", "username", "username"
#
# query = em.create_native_query <<-SQL, rsm
#   SELECT u.id, u.username
#   FROM users u
#   JOIN avatars a ON a.id = u.avatar_id
#   WHERE a.url = ?
# SQL
#
# query.set_parameter 1, "https://example.com/bob.png"
#
# users = query.get_result.map &.as(User)
# ```
#
# See `Query::ResultSetMapping` for how columns are mapped to entities and their associations.
#
# ## Parameters
#
# Parameters are written as `?` placeholders, and each is bound with `#set_parameter`, keyed by its 1-based position.
# The same placeholders work on every platform; they're rewritten to `$1`, `$2`, etc. on Postgres.
# Parameters are bound in position order, whatever order they were set in.
#
# Like entity fields, each value is converted to its database representation through a `AORM::Types::Type`.
# The type's name may be passed explicitly, otherwise it is inferred from the value:
#
# * `Int32` - `integer`
# * `Int64` - `bigint`
# * `Bool` - `boolean`
# * `Time` - `datetime`, which converts the time to UTC
#
# Values of any other type are bound without conversion.
#
# ```
# query.set_parameter 1, "george"            # Bound as is
# query.set_parameter 2, Time.local          # Converted through the `datetime` type
# query.set_parameter 3, "secret", "my_type" # Converted through the custom type registered as `my_type`
# ```
#
# TODO: Named parameters aren't supported yet.
# String keys aren't matched to `:name` placeholders; their values are bound in the order they were set.
#
# ## Results
#
# * `#get_result` returns every result
# * `#get_single_result` returns the only result, raising `AORM::Exceptions::NoResult` if there is none, or `AORM::Exceptions::NonUniqueResult` if there is more than one
# * `#get_one_or_nil_result` returns the only result, or `nil` if there is none, raising `AORM::Exceptions::NonUniqueResult` if there is more than one
#
# Each executes the query when called.
# Results are typed as `AORM::Entity`, so cast them to the mapped entity class.
#
# Hydrated entities are managed by the entity manager, so changes made to them are written on the next flush.
# Rows go through the identity map: if an entity with the same identifier is already managed, that instance is returned unchanged rather than being updated with the row's values.
class Athena::ORM::NativeQuery
  @parameters = {} of String | Int32 => {DB::Any, String?}

  # Creates a query that executes *sql* against *em*'s connection, hydrating its results according to *rsm*.
  #
  # Prefer `AORM::EntityManager#create_native_query`.
  def initialize(
    @em : EntityManagerInterface,
    @sql : String,
    @rsm : Query::ResultSetMapping,
  )
  end

  # Sets the value of the parameter at the 1-based position *key*, converted through the `Types::Type` named *type* when bound.
  #
  # Without a *type*, one is inferred from *value*.
  # See [Parameters][Athena::ORM::NativeQuery--parameters].
  def set_parameter(key : String | Int32, value : DB::Any, type : String? = nil) : self
    @parameters[key] = {value, type || Query::ParameterTypeInferer.infer_type(value)}
    self
  end

  # Returns the SQL this query executes.
  def sql : String
    @sql
  end

  # Returns the mapping this query hydrates its results with.
  def result_set_mapping : Query::ResultSetMapping
    @rsm
  end

  # Executes the query and returns all of its results.
  def get_result : Array(Entity)
    execute_and_hydrate
  end

  # Executes the query and returns its only result.
  #
  # Raises `AORM::Exceptions::NoResult` if there are no results, or `AORM::Exceptions::NonUniqueResult` if there is more than one.
  def get_single_result : Entity
    results = get_result
    raise Exceptions::NoResult.new if results.empty?
    raise Exceptions::NonUniqueResult.new if results.size > 1
    results.first
  end

  # Executes the query and returns its only result, or `nil` if there are none.
  #
  # Raises `AORM::Exceptions::NonUniqueResult` if there is more than one result.
  def get_one_or_nil_result : Entity?
    results = get_result
    raise Exceptions::NonUniqueResult.new if results.size > 1
    results.first?
  end

  private def execute_and_hydrate : Array(Entity)
    params, types = build_params
    hydration_mode = @rsm.joined_aliases.empty? ? HydrationMode::SimpleObject : HydrationMode::Object
    hydrator = @em.hydrator(hydration_mode)

    entities = [] of Entity

    @em.connection.execute_query(@sql, params, types) do |rs|
      entities = hydrator.hydrate_all(rs, @rsm)
    end

    entities
  end

  # Positional parameters bind in position order, regardless of the order they were set in.
  private def build_params : {Array(DB::Any), Array(String?)}
    parameters = @parameters.to_a

    if @parameters.keys.all?(Int32)
      parameters.sort_by! { |(key, _)| key.as(Int32) }
    end

    {parameters.map { |(_, (value, _))| value }, parameters.map { |(_, (_, type))| type }}
  end
end
