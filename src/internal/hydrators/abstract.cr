# :nodoc:
class Athena::ORM::Query::Hints
  # Hint used to collect all primary keys of associated entities during hydration and execute it in a dedicated query afterwards
  property? defer_eager_load : Bool? = nil
  getter! collection : AORM::BasePersistentCollection
  property! fetch_alias : String
  # When set, an entity already in the identity map is updated from the loaded row data instead of being returned untouched.
  # Used by `EntityManager#refresh`.
  property? refresh : Bool = false

  def initialize(
    @defer_eager_load : Bool? = nil,
    @collection : AORM::BasePersistentCollection? = nil,
    @refresh : Bool = false,
  ); end
end

# :nodoc:
#
# TODO: Maybe see about making this generic to more accurately type what `hydrate_all` returns?
abstract class Athena::ORM::Internal::Hydrators::Abstract
  # :nodoc:
  record ColumnInfo, field_name : String, type : Types::Type?, alias_name : String, is_identifier : Bool # enum_type

  private getter! rsm : AORM::Query::ResultSetMapping
  @platform : AORM::Platforms::Platform
  @uow : AORM::UnitOfWork
  @metadata_cache = Hash(AORM::Entity.class, Mapping::ClassInterface).new.compare_by_identity

  @cache : Hash(String, ColumnInfo) = Hash(String, ColumnInfo).new

  private getter! rs : DB::ResultSet
  @hints : Query::Hints = Query::Hints.new

  def initialize(@em : AORM::EntityManagerInterface)
    @platform = @em.connection.database_platform
    @uow = @em.unit_of_work
  end

  # Hydrates all rows using ResultSetMapping.
  def hydrate_all(
    @rs : DB::ResultSet,
    @rsm : AORM::Query::ResultSetMapping,
    hints : Query::Hints = Query::Hints.new,
  ) : Array(AORM::Entity)
    @rs = rs
    @rsm = rsm
    @hints = hints

    self.prepare

    begin
      self.hydrate_all_data
    ensure
      self.cleanup
    end
  end

  # Hydrates all rows from the current result set.
  # Children implement this with their specific hydration logic.
  protected abstract def hydrate_all_data : Array(AORM::Entity)

  protected def hydrate_column_info(key : String) : ColumnInfo?
    if ci = @cache[key]?
      return ci
    end

    if field_name = self.rsm.field_mappings[key]?
      class_metadata = self.class_metadata self.rsm.declaring_classes[key]
      field_mapping = class_metadata.field_mappings[field_name]
      owner_map = self.rsm.column_owner_map[key]

      column_info = ColumnInfo.new(
        field_name,
        Types::Type.get_type(field_mapping.type),
        owner_map,
        class_metadata.identifier.includes?(field_name)
      )

      # TODO: Handle discriminators

      return @cache[key] = column_info
    end

    if field_name = self.rsm.meta_mappings[key]?
      owner_map = self.rsm.column_owner_map[key]
      type = self.rsm.type_mappings[key]?.try { |type_name| Types::Type.get_type type_name }
      is_identifier = self.rsm.is_identifier_column[owner_map]?.try(&.[key]?) || false

      return @cache[key] = ColumnInfo.new(field_name, type, owner_map, is_identifier)
    end

    nil
  end

  # :nodoc:
  struct RowData
    getter data : Hash(String, Hash(String, Mapping::Value)) = Hash(String, Hash(String, Mapping::Value)).new { |hash, key| hash[key] = Hash(String, Mapping::Value).new }
    getter new_objects : Array(AORM::Entity) = [] of AORM::Entity
  end

  # Reads the current row directly from the cursor, bucketing values by RSM
  # alias/field and updating the per-alias id template + non-empty markers as
  # it goes.
  #
  # Cursor invariant: every column listed in `rs.column_names` MUST be either
  # consumed via `Type#to_crystal_value(rs, platform)` (mapped column path) or
  # explicitly skipped via `rs.read` (unmapped column path). Missing a read
  # would desynchronize subsequent rows.
  protected def gather_row_data(rs : DB::ResultSet, id : Hash(String, String), non_empty_component : Hash(String, Bool)) : RowData
    row_data = RowData.new

    rs.column_names.each do |key|
      cache_key_info = self.hydrate_column_info key

      unless cache_key_info
        # Unmapped column — must still be consumed to keep the cursor aligned.
        rs.read
        next
      end

      field_name = cache_key_info.field_name
      alias_name = cache_key_info.alias_name
      type = cache_key_info.type

      # TODO: Handle isNewObjectParameter / isScalar / discriminator collisions / inheritance overwrites

      value = type ? type.read_value(rs, @platform) : rs.read.as(DB::Any)

      row_data.data[alias_name][field_name] = Mapping::SingleValue.new value

      if cache_key_info.is_identifier && !value.nil?
        id[alias_name] += "|#{value}"
        non_empty_component[alias_name] = true
      end
    end

    # TODO: Handle nested / new objects

    row_data
  end

  protected def class_metadata(entity_class : AORM::Entity.class) : Mapping::ClassInterface
    @metadata_cache[entity_class] ||= @em.class_metadata entity_class
  end

  # Lifecycle hook called before hydration begins.
  protected def prepare : Nil
  end

  # Lifecycle hook called after hydration completes.
  protected def cleanup : Nil
    self.rs.close

    @rs = nil
    @rsm = nil
    @metadata_cache.clear
    @cache.clear

    # Eager-load any ToOne associations that couldn't be resolved during hydration (FK target not in identity map, or inverse-side load that would have nested a query inside the active cursor).
    @uow.resolve_pending_to_one_associations

    # TODO: Remove onClear event listener
  end
end
