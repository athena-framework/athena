module Athena::ORM
  # :nodoc:
  module PersisterHelper
    # Returns the types for a given field, handling both regular fields and associations.
    # For associations, returns the types of the join column(s).
    def self.type_of_field(field_name : String, metadata : Mapping::ClassInterface, em : AORM::EntityManagerInterface) : Array(String)
      if fm = metadata.field_mappings[field_name]?
        return [fm.type]
      end

      return [] of String unless assoc = metadata.association_mappings[field_name]?

      unless assoc.is_a?(Mapping::OwningSide)
        if assoc.is_a?(Mapping::InverseSide)
          return self.type_of_field(assoc.mapped_by, em.class_metadata(assoc.target_entity), em)
        end

        return [] of String
      end

      # TODO: Handle many-to-many owning side (join_table)

      types = [] of String
      target_class = em.class_metadata(assoc.target_entity)

      if assoc.is_a?(Mapping::ToOneOwningSide)
        assoc.join_columns.each do |join_column|
          types << self.type_of_column(join_column.referenced_column_name, target_class, em)
        end
      end

      types
    end

    # Returns the type for a given column name by looking up field mappings
    # and recursively resolving association join columns.
    def self.type_of_column(column_name : String, metadata : Mapping::ClassInterface, em : AORM::EntityManagerInterface) : String
      if field_name = metadata.field_names[column_name]?
        if fm = metadata.field_mappings[field_name]?
          return fm.type
        end
      end

      # Iterate over to-one owning side association mappings
      metadata.association_mappings.each_value do |assoc|
        next unless assoc.is_a? Mapping::ToOneOwningSide

        assoc.join_columns.each do |join_column|
          if join_column.name == column_name
            target_column_name = join_column.referenced_column_name
            target_class = em.class_metadata(assoc.target_entity)

            return self.type_of_column(target_column_name, target_class, em)
          end
        end
      end

      # TODO: Iterate over many-to-many owning side association mappings

      raise "Could not resolve type of column '#{column_name}' of class '#{metadata.entity_class}'"
    end

    # Returns the type name of each parameter bound when filtering *field* by a single value, in binding order.
    # Associations bind the target's identifier, so they take the type of each column their foreign key references.
    # A `nil` type binds the parameter without conversion.
    def self.infer_parameter_types(field : String, _value : _, metadata : Mapping::ClassInterface, em : AORM::EntityManagerInterface) : Array(String?)
      if fm = metadata.field_mappings[field]?
        return [fm.type] of String?
      end

      if assoc = metadata.association_mappings[field]?
        assoc = em.metadata_factory.owning_side assoc
        target_class = em.class_metadata assoc.target_entity

        columns = case assoc
                  when Mapping::ManyToManyOwningSide then assoc.relation_to_target_key_columns.values
                  when Mapping::ToOneOwningSide      then assoc.source_to_target_key_columns.values
                  else                                    raise "BUG: unexpected owning side #{assoc.class}"
                  end

        return columns.map { |column| self.type_of_column(column, target_class, em).as String? }
      end

      [nil] of String?
    end

    def self.convert_to_parameter_value(value : _, em : AORM::EntityManagerInterface)
      # TODO: Handle array values

      self.convert_individual_value value, em
    end

    private def self.convert_individual_value(value : Mapping::Value, em : AORM::EntityManagerInterface) : Array
      self.convert_individual_value value.value
    end

    private def self.convert_individual_value(value : ::Enum, em : AORM::EntityManagerInterface)
      [Mapping::EnumConversion.from_enum(value)]
    end

    private def self.convert_individual_value(value : AORM::Entity, em : AORM::EntityManagerInterface) : Array
      class_metadata = em.class_metadata value.class

      if class_metadata.is_identifier_composite
        # TODO: Handle composite PKs
      end

      [em.unit_of_work.single_identifier_value value] of DB::Any
    end

    private def self.convert_individual_value(value : Collection, em : AORM::EntityManagerInterface) : Array
      # Collections are not converted to parameter values directly.
      # They are handled by the collection persisters.
      [] of DB::Any
    end

    private def self.convert_individual_value(value : DB::Any, em : AORM::EntityManagerInterface) : Array
      [value] of DB::Any
    end

    private def self.convert_individual_value(value : _, em : AORM::EntityManagerInterface) : Array
      [value]
    end
  end
end
