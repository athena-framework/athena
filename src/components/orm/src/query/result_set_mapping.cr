# Types related to querying entities with native SQL; see `AORM::NativeQuery`.
module Athena::ORM::Query
  # Describes how the columns of a native SQL query's result map to entities, for use with `AORM::NativeQuery`.
  #
  # Each entity in the result is registered under an alias with `#add_entity_result`.
  # Its columns are then mapped to fields of that entity with `#add_field_result`.
  # A column is referenced by its name in the result, which is its alias if the SQL gives it one.
  #
  # ```
  # rsm = AORM::Query::ResultSetMapping.new
  # rsm.add_entity_result User, "u"
  # rsm.add_field_result "u", "id", "id"
  # rsm.add_field_result "u", "user_name", "username"
  #
  # em.create_native_query "SELECT u.id, u.username AS user_name FROM users u", rsm
  # ```
  #
  # Columns of the result that aren't mapped are ignored.
  #
  # WARNING: Entities are instantiated without calling their constructor, so map a column for every field the entity needs.
  # A field without a column in the result keeps its instance variable's default value, or is left uninitialized if it has none, in which case reading it is unsafe unless it's nilable.
  #
  # ## Associations
  #
  # The owning side of a ToOne association is hydrated from its foreign key column.
  # Map it with `#add_meta_result`, using the join column's name as the field name:
  #
  # ```
  # rsm.add_meta_result "u", "avatar_id", "avatar_id"
  # ```
  #
  # The related entity is then resolved as it is when loaded through the entity manager: taken from the identity map, wrapped in an unloaded `AORM::Proxy` for proxy-typed fields, or otherwise loaded once the result has been hydrated.
  # Without its foreign key column, the association is left `nil`.
  #
  # The inverse side of a ToOne association, and collections, don't need any columns.
  # Inverse ToOne associations are loaded once the result has been hydrated, and collections are loaded lazily when first used.
  #
  # TODO: Only a single entity result is supported so far.
  # Executing a query whose mapping has more than one entity result, or any `#add_joined_entity_result` or `#add_scalar_result`, raises.
  class ResultSetMapping
    # :nodoc:
    #
    # Discriminates how a result column is hydrated. Tracked alongside the
    # `columns` insertion-order list so the hydrator can dispatch per column
    # without re-deriving the column kind from the various per-kind mappings.
    enum ColumnKind
      Field
      Scalar
      Meta
    end

    # :nodoc:
    #
    # An ordered entry in the result set's column list. Insertion order matches
    # the SELECT's column order, which in turn matches the cursor read order
    # (`DB::ResultSet` advances column-by-column), so iterating `columns`
    # corresponds 1:1 with the cursor's per-row reads.
    record Column, column_name : String, kind : ColumnKind

    # :nodoc:
    #
    # Whether result mixes scalars with entities
    getter? mixed : Bool = false
    # :nodoc:
    getter? select : Bool = true

    # :nodoc:
    #
    # Maps alias names to entity class
    getter alias_map : Hash(String, AORM::Entity.class) = {} of String => AORM::Entity.class

    # :nodoc:
    #
    # Maps alias names to related association field names
    getter relation_map : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Maps alias names to parent alias names
    getter parent_alias_map : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Maps column names in result set to field names for each class
    getter field_mappings : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Map field names for each class to alias
    getter column_alias_mappings : Hash(AORM::Entity.class, Hash(String, Hash(String, String))) = Hash(AORM::Entity.class, Hash(String, Hash(String, String))).new.compare_by_identity

    # :nodoc:
    #
    # Maps column names in the result set to the alias/field name to use in the mapped result
    getter scalar_mappings : Hash(String, String | Int32) = {} of String => String | Int32

    # TODO: Handle enum mappings

    # :nodoc:
    #
    # Type mappings: column name => type name
    getter type_mappings : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Maps entities in the result set to the alias name to use in the mapped result.
    getter entity_mappings : Hash(String, String?) = {} of String => String?

    # :nodoc:
    #
    # Meta mappings: column name => field name (FKs, discriminators)
    getter meta_mappings : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Maps column names to the alias they belong to
    getter column_owner_map : Hash(String, String) = {} of String => String

    # TODO: Handle discriminator map

    # :nodoc:
    #
    # Index by: alias => column name
    getter index_by_map : Hash(String, String) = {} of String => String

    # :nodoc:
    #
    # Maps column names to class that declares the field
    getter declaring_classes : Hash(String, AORM::Entity.class) = {} of String => AORM::Entity.class

    # :nodoc:
    #
    # Identifier columns per alias: alias => column_name => true
    getter is_identifier_column : Hash(String, Hash(String, Bool)) = {} of String => Hash(String, Bool)

    # :nodoc:
    #
    # Result columns in SELECT/insertion order, each tagged with its kind.
    getter columns : Array(Column) = [] of Column

    # TODO: newObjects?
    # TODO: NestedNewObjectArgs?
    # TODO: metadataParameterMapping?
    # TODO: discriminatorMapping?
    # TODO: nestedEntities?

    # Adds an entity result of *entity_class*, referenced by *alias_name* in the rest of the mapping.
    #
    # TODO: *result_alias* names the entity within a result that mixes entities and scalar values, which isn't supported yet.
    def add_entity_result(
      entity_class : AORM::Entity.class,
      alias_name : String,
      result_alias : String? = nil,
    ) : self
      @alias_map[alias_name] = entity_class
      @entity_mappings[alias_name] = result_alias

      if result_alias
        @mixed = true
      end

      self
    end

    # Adds an entity result of *entity_class*, hydrated from the same rows as the entity under *parent_alias*, and assigned to its *relation* association.
    #
    # TODO: Joined entity results aren't supported yet; executing a query with one raises.
    def add_joined_entity_result(
      entity_class : AORM::Entity.class,
      alias_name : String,
      parent_alias : String,
      relation : String,
    ) : self
      @alias_map[alias_name] = entity_class
      @parent_alias_map[alias_name] = parent_alias
      @relation_map[alias_name] = relation
      self
    end

    # TODO: setDiscriminatorColumn

    # Maps the result column *column_name* to the field *field_name* of the entity under *alias_name*.
    #
    # The value is read through the field's `AORM::Types::Type`, as it is when loaded through the entity manager.
    # *declaring_class* is the entity class declaring the field, which defaults to the class registered under *alias_name*.
    def add_field_result(
      alias_name : String,
      column_name : String,
      field_name : String,
      declaring_class : AORM::Entity.class | Nil = nil,
    ) : self
      @field_mappings[column_name] = field_name
      @column_owner_map[column_name] = alias_name

      declaring_class = declaring_class || @alias_map[alias_name]
      @declaring_classes[column_name] = declaring_class

      unless @column_alias_mappings.has_key? declaring_class
        @column_alias_mappings[declaring_class] = Hash(String, Hash(String, String)).new do |hash2, key2|
          hash2[key2] = Hash(String, String).new
        end
      end

      @column_alias_mappings[declaring_class][alias_name][field_name] = column_name

      if !@mixed && !@scalar_mappings.empty?
        @mixed = true
      end

      @columns << Column.new(column_name, ColumnKind::Field)

      self
    end

    # Maps the result column *column_name* to a scalar value named *result_alias*, read through the `AORM::Types::Type` named *type*.
    #
    # Scalar results are columns that aren't entity fields, such as aggregates like `COUNT(*)`.
    #
    # TODO: Scalar results aren't supported yet; executing a query with one raises.
    def add_scalar_result(
      column_name : String,
      result_alias : String | Int32,
      type : String = "string",
    ) : self
      @scalar_mappings[column_name] = result_alias
      @type_mappings[column_name] = type

      if !@mixed && !@field_mappings.empty?
        @mixed = true
      end

      @columns << Column.new(column_name, ColumnKind::Scalar)

      self
    end

    # Maps the result column *column_name* to the meta field *field_name* of the entity under *alias_name*.
    #
    # Meta fields are columns of the entity's table that aren't mapped to a field, such as the foreign key column of a ToOne association, whose *field_name* is the join column's name.
    # *is_identifier* marks a column that is part of the entity's identifier, and *type* names the `AORM::Types::Type` to read the value through, which is otherwise read as returned by the driver.
    def add_meta_result(
      alias_name : String,
      column_name : String,
      field_name : String,
      is_identifier : Bool = false,
      type : String? = nil,
    ) : self
      @meta_mappings[column_name] = field_name
      @column_owner_map[column_name] = alias_name

      if is_identifier
        @is_identifier_column[alias_name] ||= {} of String => Bool
        @is_identifier_column[alias_name][column_name] = true
      end

      if type
        @type_mappings[column_name] = type
      end

      @columns << Column.new(column_name, ColumnKind::Meta)

      self
    end

    # Indexes the results of the entity under *alias_name* by its field *field_name*, which must already be mapped with `#add_field_result`.
    #
    # TODO: Indexing results isn't supported yet; the configured index has no effect.
    def add_index_by(alias_name : String, field_name : String) : self
      @field_mappings.each do |column, field|
        if field == field_name && @column_owner_map[column]? == alias_name
          @index_by_map[alias_name] = column
          return self
        end
      end

      raise "Cannot add index-by: field '#{field_name}' is not registered on alias '#{alias_name}'"
    end

    # Indexes the results of the entity under *alias_name* by the result column *column_name*.
    #
    # TODO: Indexing results isn't supported yet; the configured index has no effect.
    def add_index_by_column(alias_name : String, column_name : String) : self
      @index_by_map[alias_name] = column_name
      self
    end

    # :nodoc:
    #
    # Whether *alias_name* has an index-by configured.
    def has_index_by?(alias_name : String) : Bool
      @index_by_map.has_key? alias_name
    end

    # :nodoc:
    #
    # Whether *column_name* is registered as a regular entity-field column.
    def field_result?(column_name : String) : Bool
      @field_mappings.has_key? column_name
    end

    # :nodoc:
    #
    # Whether *column_name* is registered as a scalar result column.
    def scalar_result?(column_name : String) : Bool
      @scalar_mappings.has_key? column_name
    end

    # :nodoc:
    #
    # Whether *alias_name* has a parent alias (i.e., is a joined child).
    def has_parent_alias?(alias_name : String) : Bool
      @parent_alias_map.has_key? alias_name
    end

    # :nodoc:
    #
    # Total number of entity results (root + joined).
    def entity_result_count : Int32
      @alias_map.size
    end

    # :nodoc:
    #
    # The first registered alias — typically the root entity. Returns nil if
    # nothing has been added yet.
    def root_alias : String?
      @alias_map.first_key?
    end

    # :nodoc:
    #
    # Aliases that have a parent (i.e., joined-entity aliases).
    def joined_aliases : Array(String)
      @parent_alias_map.keys
    end

    # :nodoc:
    #
    # The entity class registered under *alias_name*. Raises if *alias_name*
    # has not been added.
    def class_metadata(alias_name : String) : AORM::Entity.class
      @alias_map[alias_name]
    end

    # :nodoc:
    #
    # The entity field name backing *column_name*. Raises if not a field
    # result.
    def field_name(column_name : String) : String
      @field_mappings[column_name]
    end

    # :nodoc:
    #
    # The owning alias for *column_name*. Raises if no owner is recorded.
    def entity_alias(column_name : String) : String
      @column_owner_map[column_name]
    end

    # :nodoc:
    #
    # Whether a column alias has been registered for *(alias_name, field_name)*.
    # Used by the persister to avoid generating duplicate column aliases for a
    # field that has already been mapped to one.
    def has_column_alias_by_field?(alias_name : String, field_name : String) : Bool
      return false unless @alias_map.has_key? alias_name

      declaring_class = @alias_map[alias_name]
      mapping = @column_alias_mappings[declaring_class]?
      mapping.try(&.[alias_name]?).try(&.has_key?(field_name)) || false
    end

    # :nodoc:
    #
    # The column alias previously registered for *(alias_name, field_name)*.
    # Use `has_column_alias_by_field?` first to verify presence; this raises
    # on missing entries.
    def column_alias_by_field(alias_name : String, field_name : String) : String
      declaring_class = @alias_map[alias_name]
      @column_alias_mappings[declaring_class][alias_name][field_name]
    end
  end
end
