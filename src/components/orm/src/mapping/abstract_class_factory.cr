require "./class_factory_interface"

# :nodoc:
abstract class Athena::ORM::Mapping::AbstractClassFactory
  include Athena::ORM::Mapping::ClassFactoryInterface

  @loaded_metadata = Hash(AORM::Entity.class, ClassInterface).new

  # Metadata shared with other factories, consulted before building it.
  property cache : MetadataCache? = nil

  def metadata(for entity_class : AORM::Entity.class) : ClassInterface
    if metadata = @loaded_metadata[entity_class]?
      return metadata
    end

    if cache = @cache
      if cached = cache[entity_class]?
        return @loaded_metadata[entity_class] = cached
      end

      self.load entity_class
      cache[entity_class] = @loaded_metadata[entity_class]
    else
      self.load entity_class
    end

    @loaded_metadata[entity_class]
  end

  private abstract def driver : Driver::Annotation
  private abstract def load(metadata : ClassInterface, parent_metadata : ClassInterface?, root_entity_found : Bool, non_superclass_parents : Array(String)) : Nil

  private def load(entity_class : AORM::Entity.class) : Nil
    # TODO: Handle loading parent types

    # Each entity subclass defines create_class_metadata via macro inherited,
    # which preserves the specific type T for annotation processing
    metadata = entity_class.create_class_metadata(self.driver)

    self.load metadata, nil, false, [] of String

    @loaded_metadata[entity_class] = metadata

    metadata
  end
end
