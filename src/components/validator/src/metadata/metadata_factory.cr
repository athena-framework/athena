require "./metadata_factory_interface"

# Basic implementation of `AVD::Metadata::MetadataFactoryInterface`.
class Athena::Validator::Metadata::MetadataFactory
  include Athena::Validator::Metadata::MetadataFactoryInterface

  def metadata(object : AVD::Validatable) : AVD::Metadata::ClassMetadata
    object.class.validation_class_metadata
  end
end
