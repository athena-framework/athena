# :nodoc:
#
# Builds and caches the `Mapping::ClassInterface` of each entity class for an entity manager.
class Athena::ORM::Mapping::ClassFactory < Athena::ORM::Mapping::AbstractClassFactory
  protected property! entity_manager : AORM::EntityManagerInterface?

  private getter target_platform : AORM::Platforms::Platform do
    self.entity_manager.connection.database_platform
  end

  private getter driver : Driver::Annotation { Driver::Annotation.new }

  private def load(metadata : ClassInterface, parent_metadata : ClassInterface?, root_entity_found : Bool, non_superclass_parents : Array(String)) : Nil
    # TODO: Handle parent
    # Note: Annotation loading is done in Entity.create_class_metadata

    if parent_metadata && root_entity_found
      # TODO: Inherit ID generator
    else
      self.complete_id_generator_mapping metadata
    end

    # TODO: handle `is_mapped_superclass`

    # TODO: Handle parent

    # TODO: Something about default discriminator map?

    # TODO: Eventing

    # TODO: Find abstract types not in discriminator map

    self.validate_runtime_metadata metadata, parent_metadata
  end

  def owning_side(assoc : Mapping::OwningSide) : Mapping::OwningSide
    assoc
  end

  def owning_side(assoc : Mapping::InverseSide) : Mapping::OwningSide
    self.metadata(assoc.target_entity).association_mappings[assoc.mapped_by].as Mapping::OwningSide
  end

  private def validate_runtime_metadata(metadata : ClassInterface, parent_metadata : ClassInterface?) : Nil
    # TODO: Validate stuff
  end

  private def complete_id_generator_mapping(metadata : ClassInterface) : Nil
    id_generator_type = metadata.id_generator_type

    if id_generator_type.auto?
      metadata.id_generator_type = self.determine_id_generator_strategy self.target_platform
    end

    case metadata.id_generator_type
    when .identity?
      platform = self.target_platform

      metadata.id_generator = if platform.supports_returning?
                                AORM::ID::ReturningGenerator.new
                              else
                                field_name = metadata.identifier.empty? ? nil : metadata.single_identifier_field_name
                                field_name && metadata.field_mappings[field_name].type == "bigint" ? AORM::ID::BigIntegerIdentityGenerator.new : AORM::ID::IdentityGenerator.new
                              end
    when .none?
      metadata.id_generator = AORM::ID::AssignedGenerator.new
    else
      # TODO: Handle other types (SEQUENCE, CUSTOM)
      raise "'#{metadata.entity_class}': the #{metadata.id_generator_type} ID generation strategy is not supported yet."
    end
  end

  private def determine_id_generator_strategy(platform : AORM::Platforms::Platform) : GeneratedValueStrategy
    em = self.entity_manager

    # TODO: Something about id generation preferences on the EM configuration?

    # TODO: Handle non-identity strategies

    GeneratedValueStrategy::IDENTITY
  end
end
