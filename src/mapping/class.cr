require "./generated_value_strategy"

# The mapping metadata of an entity class, as returned by `AORM::EntityManager#class_metadata`.
#
# Every implementation is an `AORM::Mapping::Class`, see it for the available information.
module Athena::ORM::Mapping::ClassInterface
  # Returns the entity class this metadata describes.
  abstract def entity_class : AORM::Entity.class

  # Maps each column name to the name of the field mapped to it.
  abstract def field_names : Hash(String, String)

  # Returns the mappings of the fields mapped to a column with `AORMA::Column`, keyed by property name.
  abstract def field_mappings : Hash(String, Field)

  # Returns the names of the fields making up the identifier.
  abstract def identifier : Set(String)

  # :nodoc:
  abstract def new_instance(data : Hash(String, DB::Any?)) : AORM::Entity

  # :nodoc:
  abstract def apply_data(instance : AORM::Entity, data : Hash(String, _)) : Nil

  # :nodoc:
  abstract def assign_identifier(entity : AORM::Entity, id_field : String, id_value) : Nil

  # :nodoc:
  abstract def get_field_value(entity : AORM::Entity, field_name : String)

  # :nodoc:
  abstract def set_field_value(entity : AORM::Entity, field_name : String, value) : Nil

  # :nodoc:
  abstract def create_column_value(field_name : String, value) : Mapping::Value

  # :nodoc:
  abstract def create_column_value_from_entity(field_name : String, entity : AORM::Entity) : Mapping::Value

  # :nodoc:
  abstract def create_change(field_name : String, old_value, new_value) : AORM::UnitOfWork::Change

  # :nodoc:
  abstract def inject_collection(field_name : String, entity : AORM::Entity, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)

  # :nodoc:
  abstract def promote_collection(field_name : String, entity : AORM::Entity, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)
end

# Contains the types describing how entities map to the database: class metadata, field and association mappings, and naming and quoting strategies.
module Athena::ORM::Mapping
  # :nodoc:
  #
  # Raised by the per-field accessors when *value* doesn't fit *field_name* on *entity_class*.
  # Describing an arbitrary value's class costs code proportional to every type it could be, so it's generated once here rather than in each field of every entity.
  def self.raise_type_mismatch(field_name : String, entity_class : String, value) : NoReturn
    raise "Type mismatch for '#{field_name}' on #{entity_class}: got #{value.class}"
  end

  # :nodoc:
  #
  # Raised when *id_field* isn't an identifier field on *entity_class*, or *id_value* doesn't fit it.
  def self.raise_identifier_mismatch(id_field : String, entity_class : String, id_value) : NoReturn
    raise "BUG: Field #{id_field} not found on #{entity_class} or type mismatch (got #{id_value.class})"
  end

  # :nodoc:
  #
  # Raised when a `Mapping::Class` is handed an entity of another class.
  def self.raise_entity_mismatch(method_name : String, entity_class : String, entity : AORM::Entity) : NoReturn
    raise "BUG: entity type mismatch on Class(#{entity_class})##{method_name}: got #{entity.class}"
  end
end

# :nodoc:
#
# Infers a field's column type from its Crystal type, using *typed_field_mappings* (Crystal type name => column type) on top of the defaults.
struct Athena::ORM::Mapping::TypedFieldMapper
  DEFAULT_TYPE_FIELD_MAPPINGS = {
    ::String  => "string",
    ::Bool    => "boolean",
    ::Int16   => "smallint",
    ::Int32   => "integer",
    ::Int64   => "bigint",
    ::Float32 => "smallfloat",
    ::Float64 => "float",
    ::Time    => "datetime",
    ::UUID    => "guid",
    ::Bytes   => "blob",
  }

  @typed_field_mappings : Hash(String, String)

  def initialize(typed_field_mappings : Hash(String, String) = {} of String => String)
    mappings = Hash(String, String).new

    DEFAULT_TYPE_FIELD_MAPPINGS.each do |name, type|
      mappings[name.to_s] = type
    end

    {% if @top_level.has_constant?("BigDecimal") %}
      mappings["BigDecimal"] = "number"
    {% end %}

    mappings.merge! typed_field_mappings

    @typed_field_mappings = mappings
  end

  def validate_and_complete(mapping : Driver::ColumnMapping, info : Class::FieldInfo) : Driver::ColumnMapping
    if (enum_type = info.enum_type) && mapping.enum_type.nil?
      mapping = mapping.copy_with enum_type: enum_type
    end

    return mapping unless mapping.type.nil?

    if type = @typed_field_mappings[info.type_name]?
      mapping = mapping.copy_with type: type
    end

    mapping
  end
end

# The mapping metadata of the entity class *T*: its table, the column each field is mapped to, its associations, and its identifier.
#
# The metadata is built from the entity's annotations the first time an entity manager needs it, and is then reused by that entity manager.
# Entity managers can also share it through a `AORM::Mapping::MetadataCache`, as those created by an `AORM::EntityManagerFactory` do.
# Building it raises if the mapping is invalid, such as a field whose Crystal type has no column type mapped to it.
#
# ```
# @[AORMA::Entity]
# @[AORMA::Table(name: "users")]
# class User < AORM::Entity
#   @[AORMA::Column]
#   @[AORMA::ID]
#   @[AORMA::GeneratedValue]
#   property! id : Int64
#
#   @[AORMA::Column(name: "user_name")]
#   property! username : String
# end
#
# metadata = em.class_metadata User
#
# metadata.table_name                      # => "users"
# metadata.identifier                      # => Set{"id"}
# metadata.column_name "username"          # => "user_name"
# metadata.field_mappings["username"].type # => "string"
# ```
class Athena::ORM::Mapping::Class(T)
  include Athena::ORM::Mapping::ClassInterface

  # :nodoc:
  record TableInfo, name : String? = nil, schema : String? = nil, indexes : Array(String)? = nil, unique_constraints : Array(String)? = nil, quoted : Bool = false

  # :nodoc:
  #
  # Static, type-erased metadata for a single ivar.
  # Typed read/write/wrap operations live on `Class(T)` (see `get_field_value`, `set_field_value`, `create_column_value`, etc.) so that one set of methods per entity covers every ivar — instead of one specialization per (entity × ivar-type × ivar-position) triple.
  # *type_name* is the name of the Crystal type the field's values are tracked as, which for enum fields is the integer type they're stored as.
  record FieldInfo,
    name : String,
    type_name : String,
    inferred_target_entity : AORM::Entity.class | Nil = nil,
    lazy_proxy : Bool = false,
    enum_type : String? = nil do
    def apply_type_mapping(mapper : TypedFieldMapper, mapping : Driver::ColumnMapping) : Driver::ColumnMapping
      mapper.validate_and_complete mapping, self
    end

    def apply_type_association_mapping(mapping : Driver::ColumnMapping) : Driver::ColumnMapping
      if target = @inferred_target_entity
        mapping = mapping.copy_with target_entity: target
        mapping = mapping.copy_with(lazy_proxy: true) if @lazy_proxy
      end

      mapping
    end
  end

  protected def create_pre_persist_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PrePersistEventArgs(T)
    Events::PrePersistEventArgs(T).new entity.as(T), em
  end

  protected def create_pre_remove_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PreRemoveEventArgs(T)
    Events::PreRemoveEventArgs(T).new entity.as(T), em
  end

  protected def create_post_persist_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PostPersistEventArgs(T)
    Events::PostPersistEventArgs(T).new entity.as(T), em
  end

  protected def create_post_remove_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PostRemoveEventArgs(T)
    Events::PostRemoveEventArgs(T).new entity.as(T), em
  end

  protected def create_post_update_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PostUpdateEventArgs(T)
    Events::PostUpdateEventArgs(T).new entity.as(T), em
  end

  protected def create_pre_update_event(entity : AORM::Entity, em : ORM::EntityManagerInterface) : Events::PreUpdateEventArgs(T)
    Events::PreUpdateEventArgs(T).new entity.as(T), em
  end

  # :inherit:
  getter entity_class : AORM::Entity.class

  # The repository class returned by `AORM::EntityManager#repository` for this entity, as set by `AORMA::Entity(repository_class: ...)`.
  # `nil` when the entity uses the default `AORM::EntityRepository`.
  property custom_repository_class : AORM::RepositoryInterface.class | Nil

  # Whether the entity is read-only, as set by `AORMA::Entity(read_only: true)`.
  # Changes to managed instances of a read-only entity aren't written on flush, although they can still be inserted and removed.
  property? read_only : Bool = false

  # How the values of the identifier are generated.
  # `AUTO` is resolved to the platform's preferred strategy when the metadata is built.
  property id_generator_type : AORM::Mapping::GeneratedValueStrategy = :none

  # :nodoc:
  property! id_generator : AORM::ID::AbstractGenerator

  # :nodoc:
  property? embedded_class : Bool = false

  # :nodoc:
  getter table : TableInfo

  # :nodoc:
  getter lifecycle_callbacks : Hash(AORM::Events::EventArgs.class, Array(Proc(AORM::Entity, AORM::Events::EventArgs, Nil))) do
    Hash(AORM::Events::EventArgs.class, Array(Proc(AORM::Entity, AORM::Events::EventArgs, Nil))).new do |hash, key|
      hash[key] = [] of Proc(AORM::Entity, AORM::Events::EventArgs, Nil)
    end
  end

  # :nodoc:
  def add_lifecycle_callback(event : AORM::Events::EventArgs.class, callback : Proc(AORM::Entity, AORM::Events::EventArgs, Nil)) : Nil
    if self.embedded_class?
      raise "Can't have lifecycle callbacks on embedded classes"
    end

    self.lifecycle_callbacks[event] << callback
  end

  # :inherit:
  getter field_mappings : Hash(String, Field) = Hash(String, Field).new

  # Returns the mappings of the association properties, keyed by property name.
  getter association_mappings : Hash(String, Association) = Hash(String, Association).new

  # :inherit:
  getter field_names : Hash(String, String) = Hash(String, String).new

  # Per-ivar metadata. Typed read/write/wrap operations are on the enclosing `Class(T)` (see `get_field_value`, `set_field_value`, etc.) — `FieldInfo` itself is just data.
  protected getter field_info = Hash(String, FieldInfo).new

  # :inherit:
  getter identifier : Set(String) = Set(String).new

  # Returns the kind of inheritance mapping the entity uses.
  #
  # TODO: Inheritance mapping isn't supported yet, so this is always `NONE`.
  getter inheritance_type : InheritanceType = :none

  # :nodoc:
  getter contains_foreign_identifier : Bool = false

  # :nodoc:
  getter contains_enum_identifier : Bool = false

  # Whether the identifier is made up of more than one field.
  getter is_identifier_composite : Bool = false

  # :nodoc:
  getter? requires_fetch_after_change : Bool = false

  # :nodoc:
  def initialize(
    @entity_class : AORM::Entity.class = T,
    naming_strategy : AORM::Mapping::NamingStrategyInterface? = nil,
  )
    # TODO: Handle naming strategy
    @table = TableInfo.new @entity_class.to_s.split("::").last.underscore
    @naming_strategy = naming_strategy || DefaultNamingStrategy.new

    {% for ivar in T.instance_vars %}
      {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
      {% if ivar_base_type <= AORM::Proxy %}
        {% inferred_target = ivar_base_type.type_vars.first %}
      {% elsif ivar_base_type <= AORM::Entity %}
        {% inferred_target = ivar_base_type %}
      {% elsif !ivar_base_type.type_vars.empty? && ivar_base_type.type_vars.first <= AORM::Entity %}
        {% inferred_target = ivar_base_type.type_vars.first %}
      {% else %}
        {% inferred_target = nil %}
      {% end %}

      @field_info[{{ivar.name.id.stringify}}] = FieldInfo.new(
        name: {{ivar.name.id.stringify}},
        {% if ivar_base_type < ::Enum %}
          type_name: typeof(AORM::Mapping::EnumConversion.from_enum({{ivar_base_type}}.new(0))).name,
          enum_type: {{ ivar_base_type.stringify }},
        {% else %}
          type_name: {{ ivar_base_type.stringify }},
        {% end %}
        inferred_target_entity: {{ inferred_target ? inferred_target : nil }},
        lazy_proxy: {{ ivar_base_type <= AORM::Proxy }},
      )
    {% end %}
  end

  # :nodoc:
  def get_field_value(entity : AORM::Entity, field_name : String)
    return get_field_value_typed(entity, field_name) if entity.is_a?(T)
    AORM::Mapping.raise_entity_mismatch "get_field_value", T.to_s, entity.as(AORM::Entity)
  end

  # Enum fields read as the integer they're stored as.
  private def get_field_value_typed(entity : T, field_name : String)
    {% begin %}
      case field_name
      {% for ivar in T.instance_vars %}
        {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
      when {{ivar.name.stringify}}
        {% if ivar_base_type < ::Enum %}
          entity.@{{ivar.id}}.try { |member| AORM::Mapping::EnumConversion.from_enum member }
        {% else %}
          AORM::Mapping.box entity.@{{ivar.id}}
        {% end %}
      {% end %}
      else
        raise "Unknown field '#{field_name}' on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  def set_field_value(entity : AORM::Entity, field_name : String, value) : Nil
    return set_field_value_typed(entity, field_name, value) if entity.is_a?(T)
    AORM::Mapping.raise_entity_mismatch "set_field_value", T.to_s, entity.as(AORM::Entity)
  end

  # Enum fields also accept the integer they're stored as.
  private def set_field_value_typed(entity : T, field_name : String, value) : Nil
    {% begin %}
      case field_name
      {% for ivar in T.instance_vars %}
        {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
      when {{ivar.name.stringify}}
        {% if ivar_base_type < ::Enum %}
          if value.is_a?(Int)
            pointerof(entity.@{{ivar.id}}).value = {{ivar_base_type}}.from_value(value)
            return
          end
        {% end %}

        {% for member in ivar.type.union_types %}
          {% unless member == Nil || member <= ::DB::Any || member <= AORM::Entity || member <= AORM::BaseCollection || member <= AORM::Collection %}
            value = value.value if value.is_a?(AORM::Mapping::OpaqueValue({{member}}))
          {% end %}
        {% end %}

        if value.is_a?({{ivar.type}})
          # Explicit `.as` because narrowing through a `ValueAny` caller doesn't always refine `value` to exactly `ivar.type` — Crystal may keep `Entity+ | Nil` instead of e.g. `Avatar | Nil`.
          pointerof(entity.@{{ivar.id}}).value = value.as({{ivar.type}})
        else
          AORM::Mapping.raise_type_mismatch field_name, T.to_s, value
        end
      {% end %}
      else
        raise "Unknown field '#{field_name}' on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  #
  # Wraps an already-extracted value as a `Mapping::Value` for *field_name*.
  # Pass-through if *value* is already a `Mapping::Value`.
  # Enum fields are wrapped as the integer they're stored as, whether given a member or that integer.
  def create_column_value(field_name : String, value) : Mapping::Value
    return value if value.is_a?(Mapping::Value)

    {% begin %}
      case field_name
      {% for ivar in T.instance_vars %}
        {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
      when {{ivar.name.stringify}}
        {% if ivar_base_type < ::Enum %}
          return Mapping::ColumnValue.new(field_name, AORM::Mapping::EnumConversion.from_enum(value)) if value.is_a?({{ivar_base_type}})
          return Mapping::ColumnValue.new(field_name, AORM::Mapping::EnumConversion.from_enum({{ivar_base_type}}.from_value(value))) if value.is_a?(Int)
        {% end %}

        {% for member in ivar.type.union_types %}
          {% unless member == Nil || member <= ::DB::Any || member <= AORM::Entity || member <= AORM::BaseCollection || member <= AORM::Collection %}
            return Mapping::ColumnValue.new(field_name, value) if value.is_a?(AORM::Mapping::OpaqueValue({{member}}))
          {% end %}
        {% end %}

        if value.is_a?({{ivar.type}})
          Mapping::ColumnValue.new(field_name, AORM::Mapping.box(value))
        else
          AORM::Mapping.raise_type_mismatch field_name, T.to_s, value
        end
      {% end %}
      else
        raise "Unknown field '#{field_name}' on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  #
  # Reads *field_name* off *entity* and wraps it as a `Mapping::Value`.
  def create_column_value_from_entity(field_name : String, entity : AORM::Entity) : Mapping::Value
    return create_column_value_from_entity_typed(field_name, entity) if entity.is_a?(T)
    AORM::Mapping.raise_entity_mismatch "create_column_value_from_entity", T.to_s, entity.as(AORM::Entity)
  end

  private def create_column_value_from_entity_typed(field_name : String, entity : T) : Mapping::Value
    {% begin %}
      case field_name
      {% for ivar in T.instance_vars %}
        {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
      when {{ivar.name.stringify}}
        {% if ivar_base_type < ::Enum %}
          Mapping::ColumnValue.new(field_name, entity.@{{ivar.id}}.try { |member| AORM::Mapping::EnumConversion.from_enum member })
        {% else %}
          Mapping::ColumnValue.new(field_name, AORM::Mapping.box(entity.@{{ivar.id}}))
        {% end %}
      {% end %}
      else
        raise "Unknown field '#{field_name}' on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  def create_change(field_name : String, old_value, new_value) : AORM::UnitOfWork::Change
    AORM::UnitOfWork::Change.new(
      old_value ? self.create_column_value(field_name, old_value) : nil,
      self.create_column_value(field_name, new_value),
    )
  end

  # :nodoc:
  def inject_collection(field_name : String, entity : AORM::Entity, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)
    return inject_collection_typed(field_name, entity, em, metadata, assoc) if entity.is_a?(T)
    AORM::Mapping.raise_entity_mismatch "inject_collection", T.to_s, entity.as(AORM::Entity)
  end

  private def inject_collection_typed(field_name : String, entity : T, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)
    {% begin %}
      case field_name
      {% for ivar, idx in T.instance_vars %}
        {% if ivar.type <= Athena::ORM::Collection %}
          when {{ivar.name.stringify}}
            {% element_type = T.instance_vars[idx].default_value.receiver.type_vars.first %}
            p_coll = AORM::PersistentCollection({{element_type}}).new em, metadata, AORM::ArrayCollection({{element_type}}).new
            p_coll.set_owner entity, assoc
            p_coll.initialized = false

            pointerof(entity.@{{ivar.id}}).value = p_coll
            p_coll
        {% end %}
      {% end %}
      else
        raise "BUG: Not a collection field: #{field_name} on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  def promote_collection(field_name : String, entity : AORM::Entity, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)
    return promote_collection_typed(field_name, entity, em, metadata, assoc) if entity.is_a?(T)
    AORM::Mapping.raise_entity_mismatch "promote_collection", T.to_s, entity.as(AORM::Entity)
  end

  private def promote_collection_typed(field_name : String, entity : T, em : AORM::EntityManagerInterface, metadata : Mapping::ClassInterface, assoc : Mapping::Association)
    {% begin %}
      case field_name
      {% for ivar, idx in T.instance_vars %}
        {% if ivar.type <= Athena::ORM::Collection %}
          when {{ivar.name.stringify}}
            {% element_type = T.instance_vars[idx].default_value.receiver.type_vars.first %}
            current = entity.@{{ivar.id}}

            if current.is_a?(AORM::PersistentCollection({{element_type}})) && current.owner == entity
              current
            else
              items = current.is_a?(AORM::Collection({{element_type}})) ? current.to_a : Array({{element_type}}).new
              backing = AORM::ArrayCollection({{element_type}}).new items
              p_coll = AORM::PersistentCollection({{element_type}}).new em, metadata, backing
              p_coll.set_owner entity, assoc
              p_coll.mark_dirty unless backing.empty?

              pointerof(entity.@{{ivar.id}}).value = p_coll
              p_coll
            end
        {% end %}
      {% end %}
      else
        raise "BUG: Not a collection field: #{field_name} on #{T}"
      end
    {% end %}
  end

  # :nodoc:
  def new_instance(data : Hash(String, _)) : AORM::Entity
    {% begin %}
      {% if T.abstract? %}
        raise "Cannot instantiate abstract entity {{T}}"
      {% else %}
        instance = T.allocate
        self.apply_data instance, data
        instance
      {% end %}
    {% end %}
  end

  # :nodoc:
  #
  # Writes scalar field values from *data* onto an existing entity instance, leaving association/collection ivars alone.
  # Used by `new_instance` for initial hydration and by `UnitOfWork#refresh` to update the in-memory state of a managed entity from the latest DB row.
  def apply_data(instance : AORM::Entity, data : Hash(String, _)) : Nil
    {% begin %}
      {% if T.abstract? %}
        raise "Cannot apply data to abstract entity {{T}}"
      {% else %}
        typed_instance = instance.as({{T}})
        {% for ivar in T.instance_vars %}
          # Present keys are applied even when `false` or `nil`, so a refresh can overwrite those values too.
          if data.has_key?({{ ivar.name.stringify }})
            raw = data[{{ ivar.name.stringify }}]
            raw = raw.is_a?(Mapping::Value) ? raw.value : raw

            {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
            {% if ivar_base_type < ::Enum %}
              raw = {{ivar_base_type}}.from_value(raw) if raw.is_a?(Int)
            {% end %}

            {% for member in ivar.type.union_types %}
              {% unless member == Nil || member <= ::DB::Any || member <= AORM::Entity || member <= AORM::BaseCollection || member <= AORM::Collection %}
                raw = raw.value if raw.is_a?(AORM::Mapping::OpaqueValue({{member}}))
              {% end %}
            {% end %}

            if raw.is_a?({{ivar.type}})
              pointerof(typed_instance.@{{ ivar.id }}).value = raw.as({{ ivar.type }})
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end

  # Returns the name of the `AORM::Types::Type` of the field named *field_name*, or `nil` if it isn't mapped to a column.
  def type_of_field(field_name : String) : String?
    (fm = @field_mappings[field_name]?) ? fm.type : nil
  end

  # Returns the name of the identifier field.
  #
  # Raises if the identifier is composite, or the entity has no identifier.
  def single_identifier_field_name : String
    raise "single id not allowed on composite primary key" if @is_identifier_composite

    raise "no ID defined" unless id = @identifier.first?

    id
  end

  # Returns the column name of the identifier field.
  #
  # Raises if the identifier is composite, or the entity has no identifier.
  def single_identifier_column_name : String
    self.column_name(self.single_identifier_field_name)
  end

  # :nodoc:
  def field_value(entity : AORM::Entity, field_name : String)
    self.get_field_value entity, field_name
  end

  # Returns whether the field named *field_name* is part of the identifier.
  def is_identifier(field_name : String) : Bool
    return false if @identifier.empty?

    return field_name == @identifier.first if !@is_identifier_composite

    @identifier.includes? field_name
  end

  # :nodoc:
  def identifier_values(entity : T) : Hash
    if @is_identifier_composite
      # Fields without a value are left out, as a single identifier without one is.
      return @identifier.to_h { |field| {field, self.get_field_value(entity, field)} }.compact
    end

    id = @identifier.first
    value = self.get_field_value entity, id

    if value.nil?
      return {} of String => NoReturn
    end

    {id => value}
  end

  # :nodoc:
  #
  # TODO: Is there a better way to handle this?
  def identifier_values(entity : _) : NoReturn
    raise "BUG: Invoked wrong overload"
  end

  # :nodoc:
  def set_identifier_values(entity : AORM::Entity, id : Hash(String, _)) : Nil
    id.each do |id_field, id_value|
      self.set_field_value entity, id_field, id_value
    end
  end

  # :nodoc:
  def assign_identifier(entity : AORM::Entity, id_field : String, id_value) : Nil
    {% begin %}
      typed_entity = entity.as(T)
      {% for ivar in T.instance_vars %}
        if id_field == {{ivar.name.id.stringify}}
          {% ivar_base_type = ivar.type.nilable? ? ivar.type.union_types.reject(&.nilable?).first : ivar.type %}
          {% if ivar_base_type < ::Enum %}
            if id_value.is_a?(Int)
              pointerof(typed_entity.@{{ ivar.id }}).value = {{ivar_base_type}}.from_value(id_value)
              return
            end
          {% end %}

          {% for member in ivar.type.union_types %}
            {% unless member == Nil || member <= ::DB::Any || member <= AORM::Entity || member <= AORM::BaseCollection || member <= AORM::Collection %}
              id_value = id_value.value if id_value.is_a?(AORM::Mapping::OpaqueValue({{member}}))
            {% end %}
          {% end %}

          if id_value.is_a?({{ ivar_base_type }})
            pointerof(typed_entity.@{{ ivar.id }}).value = id_value
            return
          end
        end
      {% end %}
      AORM::Mapping.raise_identifier_mismatch id_field, T.to_s, id_value
    {% end %}
  end

  # Returns whether the identifier values are assigned by your code, rather than generated.
  def identifier_natural? : Bool
    @id_generator_type.none?
  end

  # Returns whether the database generates the identifier values when inserting rows.
  def identifier_identity? : Bool
    @id_generator_type.identity?
  end

  # Returns the column name of the field named *field_name*, without quotes.
  # Returns *field_name* itself if it isn't mapped to a column.
  def column_name(field_name : String) : String
    @field_mappings[field_name]?.try(&.column_name) || field_name
  end

  # Returns the name of the entity's table, without quotes.
  #
  # Defaults to the underscored class name, e.g. `user_profile` for `App::UserProfile`, unless set with `AORMA::Table`.
  def table_name : String
    @table.name.not_nil!
  end

  # :nodoc:
  def map_field(mapping : Driver::ColumnMapping) : Nil
    mapping = self.validate_and_complete_field_mapping mapping
    self.assert_field_not_mapped mapping.field_name

    if mapping.generated == true
      @requires_fetch_after_change = true
    end

    @field_mappings[mapping.field_name] = mapping
  end

  private def validate_and_complete_field_mapping(mapping : Driver::ColumnMapping) : Field
    raise "Missing field name" if mapping.field_name.nil?

    # mapping = TypedFieldMapper.new.validate_and_complete(mapping, @field_info[mapping.field_name])
    mapping = @field_info[mapping.field_name].apply_type_mapping TypedFieldMapper.new, mapping

    # A field's Crystal type is always known, so instead of defaulting to `string`, which couldn't read a value of another type back, an unmapped type is an error.
    if mapping.type.nil?
      raise "'#{T}##{mapping.field_name}': no column type is mapped to #{@field_info[mapping.field_name].type_name}, so pass one with `@[AORMA::Column(type: ...)]`."
    end

    if mapping.column_name.nil?
      mapping = mapping.copy_with column_name: @naming_strategy.property_to_column_name(mapping.field_name, @entity_class)
    end

    mapping = Field.from_column_mapping mapping

    if mapping.column_name.starts_with?('`')
      mapping = mapping.copy_with column_name: mapping.column_name.strip('`'), quoted: true
    end

    # TODO: Handle discriminator maps
    if @field_names.has_key? mapping.column_name
      raise "Duplicate column name '#{mapping.column_name}'."
    end

    @field_names[mapping.column_name] = mapping.field_name

    if mapping.id == true
      # TODO: Handle version field
      @identifier << mapping.field_name

      if !@is_identifier_composite && @identifier.size > 1
        @is_identifier_composite = true
      end
    end

    # TODO: Handle `generated` property

    if mapping.enum_type
      # Enum fields are always tracked and bound as their integer value.
      unless mapping.type.in?(Types::INTEGER, Types::BIGINT)
        raise "Enum field '#{mapping.field_name}' on #{T} must be mapped to an integer type, got '#{mapping.type}'"
      end
    end

    mapping
  end

  # :nodoc:
  def map_one_to_one(mapping : Driver::ColumnMapping) : Nil
    mapping = mapping.copy_with type: "one_to_one"

    mapping = self.validate_and_complete_association_mapping mapping

    self.store_association_mapping mapping
  end

  # :nodoc:
  def map_many_to_many(mapping : Driver::ColumnMapping) : Nil
    mapping = mapping.copy_with type: "many_to_many"

    mapping = self.validate_and_complete_association_mapping mapping

    self.store_association_mapping mapping
  end

  # :nodoc:
  def map_one_to_many(mapping : Driver::ColumnMapping) : Nil
    mapping = mapping.copy_with type: "one_to_many"

    mapping = self.validate_and_complete_association_mapping mapping

    self.store_association_mapping mapping
  end

  # :nodoc:
  def map_many_to_one(mapping : Driver::ColumnMapping) : Nil
    mapping = mapping.copy_with type: "many_to_one"

    mapping = self.validate_and_complete_association_mapping mapping

    self.store_association_mapping mapping
  end

  # :nodoc:
  def validate_and_complete_association_mapping(mapping : Driver::ColumnMapping) : Association
    # TODO: Handle unsetting things?

    mapping = mapping.copy_with is_owning_side: true, source_entity: @entity_class
    mapping = @field_info[mapping.field_name].apply_type_association_mapping mapping

    if "many_to_one" == mapping.type && mapping.orphan_removal
      raise "illegal orphan removal"
    end

    # TODO: Handle PK FKs

    raise "Missing field name" if mapping.field_name.nil?
    raise "Missing target entity" if mapping.target_entity.nil?

    if !(mapped_by = mapping.mapped_by) # && !(join_table = mapping.join_table)
      # TODO: Handle join table info
    else
      mapping = mapping.copy_with is_owning_side: false
    end

    if mapping.id && mapping.type.try &.ends_with? "to_many"
      raise "illegal to many identifier association"
    end

    unless mapping.fetch_mode
      mapping = mapping.copy_with fetch_mode: FetchMode::LAZY
    end

    cascades = (arr = mapping.cascade) ? arr.map! &.downcase : [] of String
    all_cascades = ["remove", "persist", "refresh", "detach"]

    if cascades.includes? "all"
      cascades = all_cascades
    else
      # TODO: Validate cascades
    end

    mapping = mapping.copy_with cascade: cascades

    case mapping.type
    when "one_to_one"
      mapping.is_owning_side ? OneToOneOwningSide.new(
        mapping,
        @naming_strategy,
        @entity_class,
        @table,
        self.inheritance_type.single_table?
      ) : OneToOneInverseSide.new mapping, T.to_s
    when "many_to_many"
      mapping.is_owning_side ? ManyToManyOwningSide.new(
        mapping,
        @naming_strategy,
        @entity_class,
        mapping.target_entity.not_nil!
      ) : ManyToManyInverseSide.new mapping
    when "one_to_many"
      OneToManyInverseSide.new mapping
    when "many_to_one"
      ManyToOneOwningSide.new(
        mapping,
        @naming_strategy,
        @entity_class,
        @table,
        self.inheritance_type.single_table?
      )
    else
      raise "Invalid association type"
    end
  end

  # :nodoc:
  def store_association_mapping(mapping : Association) : Nil
    self.assert_field_not_mapped source_field_name = mapping.field_name

    @association_mappings[source_field_name] = mapping
  end

  private def assert_field_not_mapped(field_name : String)
    if @field_mappings.has_key? field_name
      raise "Duplicate field mapping '#{field_name}'."
    end
  end

  # :nodoc:
  def primary_table=(table : Driver::TableMapping) : Nil
    if name = table.name
      # A name like `myschema.mytable` holds the schema too.
      if name.includes? '.'
        schema, name = name.split '.', 2
        @table = @table.copy_with schema: schema
      end

      if name.starts_with?('`')
        @table = @table.copy_with name: name.strip('`'), quoted: true
      else
        @table = @table.copy_with name: name
      end
    end

    if quoted = table.quoted
      @table = @table.copy_with quoted: quoted
    end

    if schema = table.schema
      @table = @table.copy_with schema: schema
    end

    # TODO: Handle indexes, unique_constraints, and options
  end
end
