module Athena::Validator::Metadata::MetadataFactoryInterface
  # Returns an `AVD::Metadata::ClassMetadata` instance for the related `AVD::Validatable` *object*.
  abstract def metadata(object : AVD::Validatable) : AVD::Metadata::ClassMetadata
end
