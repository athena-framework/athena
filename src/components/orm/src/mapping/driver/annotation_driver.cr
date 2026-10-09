# :nodoc:
module Athena::ORM::Mapping::Driver
  # Strongly-typed mapping records consumed by `Annotation#load_metadata_for_entity`.
  # Kept separate from the `@[AORMA::*]` annotation records so the loader can
  # normalize/default fields without mutating user-facing annotation data.

  record TableMapping,
    name : String? = nil,
    schema : String? = nil,
    quoted : Bool? = nil

  # Holds join column definition from annotation for passing to mapping constructors.
  record JoinColumnDef,
    name : String?,
    referenced_column_name : String?,
    nullable : Bool? = nil,
    on_delete : String? = nil

  record ColumnMapping,
    field_name : String,
    type : String? = nil,
    column_name : String? = nil,
    length : Int32? = nil,
    precision : Int32? = nil,
    scale : Int32? = nil,
    unique : Bool? = nil,
    nullable : Bool? = nil,
    not_insertable : Bool? = nil,
    not_updatable : Bool? = nil,
    enum_type : String? = nil,
    column_definition : String? = nil,
    generated : String? = nil,
    index : Bool = false,
    id : Bool? = nil,
    quoted : Bool? = nil,
    source_entity : AORM::Entity.class | Nil = nil,
    target_entity : AORM::Entity.class | Nil = nil,
    join_columns : Array(String)? = nil,
    inversed_by : String? = nil,
    mapped_by : String? = nil,
    cascade : Array(String)? = nil,
    orphan_removal : Bool? = nil,
    fetch_mode : FetchMode? = nil,
    is_owning_side : Bool? = nil,
    join_table : Hash(String, String)? = nil,
    index_by : String? = nil,
    join_column_defs : Array(JoinColumnDef)? = nil,
    inverse_join_column_defs : Array(JoinColumnDef)? = nil,
    lazy_proxy : Bool = false

  struct Annotation
    # Rejected here rather than in `#load_metadata_for_entity`: a parent class's metadata is loaded with its virtual type, and macros see no annotations on virtual types.
    macro finished
      {% for type in AORM::Entity.all_subclasses %}
        {% for unsupported in [{AORMA::Embeddable, "embeddables", ""}] %}
          {% if ann = type.annotation unsupported[0] %}
            {% ann.raise "'#{type}': #{unsupported[1].id} are not supported yet.#{unsupported[2].id}" %}
          {% end %}
        {% end %}
      {% end %}
    end

    def load_metadata_for_entity(metadata : Mapping::Class(T)) : Nil forall T
      {% if ann = T.annotation AORMA::Entity %}
        entity_ann = AORM::Mapping::Annotations::Entity.new({{ann.named_args.double_splat}})
        if repo_class = entity_ann.repository_class
          metadata.custom_repository_class = repo_class
        end

        if entity_ann.read_only
          metadata.read_only = true
        end


      {% elsif T.annotation AORMA::Embeddable %}
        # TODO: This
      {% else %}
        # An abstract parent class without `@[AORMA::Entity]` shares its mapped properties with the entities inheriting from it, which read them through their own `T.instance_vars`, so it never needs metadata of its own.
        {% raise T.raise "'#{T}' is not a valid entity or superclass" unless T == AORM::Entity || T.abstract? %}
      {% end %}

      primary_table = nil

      {% if ann = T.annotation AORMA::Table %}
        table_ann = AORM::Mapping::Annotations::Table.new({% unless ann.args.empty? %}{{ann.args.splat}},{% end %} {{ann.named_args.double_splat}})
        primary_table = TableMapping.new table_ann.name, table_ann.schema

        # TODO: Support table options?
      {% end %}

      # TODO: Handle `Index` annotation

      # TODO: Handle `UniqueConstraint` annotation

      if primary_table
        metadata.primary_table = primary_table
      end

      # TODO: Handle `Cache` annotation

      # TODO: Handle `InheritanceType` annotation

      # TODO: Handle `ChangeTrackingPolicy` annotation

      {% for ivar, idx in T.instance_vars %}
        mapping = ColumnMapping.new field_name: {{ivar.name.id.stringify}}

        {% if ann = ivar.annotation AORMA::Column %}
          {% ann[:generated].raise "'#{T.name}##{ivar.name}': the 'generated' column option is not supported yet." if ann[:generated] %}

          mapping = self.column_ann_to_mapping {{ivar.name.id.stringify}}, AORM::Mapping::Annotations::Column.new({{ann.named_args.double_splat}})

          {% if ivar.annotation AORMA::ID %}
            mapping = mapping.copy_with id: true
          {% end %}

          {% if ann = ivar.annotation AORMA::GeneratedValue %}
            metadata.id_generator_type = AORM::Mapping::Annotations::GeneratedValue.new({{ann.named_args.double_splat}}).strategy
          {% end %}

          # TODO: Handle `Version` annotation

          metadata.map_field mapping
        {% elsif ann = ivar.annotation AORMA::OneToOne %}
          one_to_one_ann = AORM::Mapping::Annotations::OneToOne.new({{ann.named_args.double_splat}})

          if metadata.embedded_class?
            raise "Can't use OneToOne on embedded class"
          end

          {% if ivar.annotation AORMA::ID %}
            mapping = mapping.copy_with id: true
          {% end %}

          mapping = mapping.copy_with(
            target_entity: one_to_one_ann.target_entity,
            join_columns: [] of String,
            mapped_by: one_to_one_ann.mapped_by,
            inversed_by: one_to_one_ann.inversed_by,
            cascade: one_to_one_ann.cascade,
            orphan_removal: one_to_one_ann.orphan_removal,
            fetch_mode: one_to_one_ann.fetch_mode
          )

          # Collect JoinColumn annotations — the FK column lives on this entity.
          {% join_col_anns = ivar.annotations AORMA::JoinColumn %}
          {% unless join_col_anns.empty? %}
            join_col_defs = [] of JoinColumnDef
            {% for jc_ann in join_col_anns %}
              join_col_defs << JoinColumnDef.new(
                name: {{jc_ann[:name]}},
                referenced_column_name: {{jc_ann[:referenced_column_name]}},
                nullable: {{jc_ann[:nullable]}},
                on_delete: {{jc_ann[:on_delete]}}
              )
            {% end %}
            mapping = mapping.copy_with(join_column_defs: join_col_defs)
          {% end %}

          metadata.map_one_to_one mapping
        {% elsif ann = ivar.annotation AORMA::OneToMany %}
          one_to_many_ann = AORM::Mapping::Annotations::OneToMany.new({{ann.named_args.double_splat}})

          if metadata.embedded_class?
            raise "Can't use OneToMany on embedded class"
          end

          mapping = mapping.copy_with(
            target_entity: one_to_many_ann.target_entity,
            mapped_by: one_to_many_ann.mapped_by,
            cascade: one_to_many_ann.cascade,
            orphan_removal: one_to_many_ann.orphan_removal,
            fetch_mode: one_to_many_ann.fetch_mode,
            index_by: one_to_many_ann.index_by
          )

          metadata.map_one_to_many mapping
        {% elsif ann = ivar.annotation AORMA::ManyToOne %}
          many_to_one_ann = AORM::Mapping::Annotations::ManyToOne.new({{ann.named_args.double_splat}})

          if metadata.embedded_class?
            raise "Can't use ManyToOne on embedded class"
          end

          {% if ivar.annotation AORMA::ID %}
            mapping = mapping.copy_with id: true
          {% end %}

          mapping = mapping.copy_with(
            target_entity: many_to_one_ann.target_entity,
            join_columns: [] of String,
            inversed_by: many_to_one_ann.inversed_by,
            cascade: many_to_one_ann.cascade,
            fetch_mode: many_to_one_ann.fetch_mode
          )

          # Collect JoinColumn annotations — the FK column lives on this entity.
          {% join_col_anns = ivar.annotations AORMA::JoinColumn %}
          {% unless join_col_anns.empty? %}
            join_col_defs = [] of JoinColumnDef
            {% for jc_ann in join_col_anns %}
              join_col_defs << JoinColumnDef.new(
                name: {{jc_ann[:name]}},
                referenced_column_name: {{jc_ann[:referenced_column_name]}},
                nullable: {{jc_ann[:nullable]}},
                on_delete: {{jc_ann[:on_delete]}}
              )
            {% end %}
            mapping = mapping.copy_with(join_column_defs: join_col_defs)
          {% end %}

          metadata.map_many_to_one mapping
        {% elsif ann = ivar.annotation AORMA::ManyToMany %}
          many_to_many_ann = AORM::Mapping::Annotations::ManyToMany.new({{ann.named_args.double_splat}})

          if metadata.embedded_class?
            raise "Can't use ManyToMany on embedded class"
          end

          mapping = mapping.copy_with(
            target_entity: many_to_many_ann.target_entity,
            mapped_by: many_to_many_ann.mapped_by,
            inversed_by: many_to_many_ann.inversed_by,
            cascade: many_to_many_ann.cascade,
            orphan_removal: many_to_many_ann.orphan_removal,
            fetch_mode: many_to_many_ann.fetch_mode,
            index_by: many_to_many_ann.index_by
          )

          {% if jt_ann = ivar.annotation AORMA::JoinTable %}
            join_table_ann = AORM::Mapping::Annotations::JoinTable.new({{jt_ann.named_args.double_splat}})

            if jt_name = join_table_ann.name
              jt_hash = {"name" => jt_name}
              if jt_schema = join_table_ann.schema
                jt_hash["schema"] = jt_schema
              end
              mapping = mapping.copy_with(join_table: jt_hash)
            end
          {% end %}

          # Collect JoinColumn annotations (source entity to join table)
          {% join_col_anns = ivar.annotations AORMA::JoinColumn %}
          {% unless join_col_anns.empty? %}
            join_col_defs = [] of JoinColumnDef
            {% for jc_ann in join_col_anns %}
              join_col_defs << JoinColumnDef.new(
                name: {{jc_ann[:name]}},
                referenced_column_name: {{jc_ann[:referenced_column_name]}},
                on_delete: {{jc_ann[:on_delete]}}
              )
            {% end %}
            mapping = mapping.copy_with(join_column_defs: join_col_defs)
          {% end %}

          # Collect InverseJoinColumn annotations (join table to target entity)
          {% inv_join_col_anns = ivar.annotations AORMA::InverseJoinColumn %}
          {% unless inv_join_col_anns.empty? %}
            inv_join_col_defs = [] of JoinColumnDef
            {% for ijc_ann in inv_join_col_anns %}
              inv_join_col_defs << JoinColumnDef.new(
                name: {{ijc_ann[:name]}},
                referenced_column_name: {{ijc_ann[:referenced_column_name]}},
                on_delete: {{ijc_ann[:on_delete]}}
              )
            {% end %}
            mapping = mapping.copy_with(inverse_join_column_defs: inv_join_col_defs)
          {% end %}

          # TODO: Handle OrderBy

          metadata.map_many_to_many mapping
        {% end %}
      {% end %}

      # TODO: Handle `AssociationOverrides` annotation

      # TODO: Handle `AttributeOverrides` annotation

      # TODO: Handle `EntityListeners` annotation

      {% begin %}
        {% events = [
             # annotation, event type
             {AORMA::PostLoad, AORM::Events::PostLoadEventArgs},
             {AORMA::PostPersist, AORM::Events::PostPersistEventArgs},
             {AORMA::PostRemove, AORM::Events::PostRemoveEventArgs},
             {AORMA::PostUpdate, AORM::Events::PostUpdateEventArgs},
             {AORMA::PreFlush, AORM::Events::PreFlushEventArgs},
             {AORMA::PrePersist, AORM::Events::PrePersistEventArgs},
             {AORMA::PreRemove, AORM::Events::PreRemoveEventArgs},
             {AORMA::PreUpdate, AORM::Events::PreUpdateEventArgs},
           ] %}

        {%
          # Includes callbacks declared in included modules.
          # Each method's most-derived definition decides, so an override without the annotation drops the module's callback.
          all_methods = T.all_methods
          callback_names = all_methods.select { |method| events.any? { |ev| method.annotation ev[0] } }.map(&.name).uniq
          callbacks = callback_names.map { |name| all_methods.find { |method| method.name == name } }
        %}

        {% for ev in events %}
          {%
            ann_type, event_type = ev

            expanded_event_type = "#{event_type.name(generic_args: false)}#{event_type.type_vars.size > 0 ? "(#{T})".id : "".id}".id
          %}
          {% for callback in callbacks.select(&.annotation(ann_type)) %}
            {%
              if ann_type.resolve == AORMA::PostLoad.resolve
                callback.raise "'#{T.name}##{callback.name}': PostLoad lifecycle callbacks are not supported yet."
              end

              if callback.args.size > 1
                callback.raise "Expected '#{T.name}##{callback.name}' to have 0..1 parameters, got '#{callback.args.size}'."
              end

              event_arg = callback.args[0]

              if event_arg && !(event_arg.restriction.resolve <= event_type)
                event_arg.raise "'#{T.name}##{callback.name}': event parameter must have a type restriction of '#{expanded_event_type}', not '#{event_arg.restriction}'."
              end
            %}


            metadata.add_lifecycle_callback({{expanded_event_type}}, Proc(AORM::Entity, AORM::Events::EventArgs, Nil).new do |obj, event|
              obj.as({{T}}).{{callback.name.id}}{% if callback.args.size == 1 %} event.as({{expanded_event_type}}){% end %}
            end)
          {% end %}
        {% end %}
      {% end %}
    end

    private def load(entity_class : T.class) : Nil forall T
    end

    private def column_ann_to_mapping(field_name : String, ann : AORM::Mapping::Annotations::Column) : ColumnMapping
      mapping = ColumnMapping.new(
        field_name: field_name,
        type: ann.type,
        scale: ann.scale,
        length: ann.length,
        precision: ann.precision,
        unique: ann.unique,
        nullable: ann.nullable,
        index: ann.index,
      )

      if value = ann.name
        mapping = mapping.copy_with column_name: value
      end

      if value = ann.column_definition
        mapping = mapping.copy_with column_definition: value
      end

      if ann.updatable == false
        mapping = mapping.copy_with not_updatable: true
      end

      if ann.insertable == false
        mapping = mapping.copy_with not_insertable: true
      end

      if value = ann.generated
        mapping = mapping.copy_with generated: value
      end

      mapping
    end
  end
end
