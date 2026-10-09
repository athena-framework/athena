# :nodoc:
struct Athena::ORM::ID::AssignedGenerator < Athena::ORM::ID::AbstractGenerator
  # :inherit:
  def generate(em : AORM::EntityManagerInterface, entity : AORM::Entity? = nil) : Hash
    entity = entity.not_nil!

    class_metadata = em.class_metadata entity.class
    identifier = Hash(String, Mapping::Value).new

    class_metadata.identifier.each do |id_field|
      value = class_metadata.create_column_value_from_entity id_field, entity

      if value.nil?
        raise "entity missing assigned ID"
      end

      if class_metadata.association_mappings.has_key?(id_field) && value.is_a?(AORM::Entity)
        value = em.unit_of_work.single_identifier_value value
      end

      identifier[id_field] = value
    end

    identifier
  end
end
