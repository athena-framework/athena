# :nodoc:
#
# Converts entity identifiers into scalar string keys for identity map lookups.
# Extracted from UnitOfWork to allow reuse in persisters and cache hydrators.
class Athena::ORM::Utility::IdentifierFlattener
  def initialize(
    @unit_of_work : AORM::UnitOfWork,
    @metadata_factory : AORM::Mapping::ClassFactory,
  )
  end

  def flatten_identifier(class_metadata : AORM::Mapping::ClassInterface, id : Hash(String, _)) : Hash
    class_metadata.identifier.to_h do |field|
      # TODO: Handle associations

      {field, id[field]}
    end
  end
end
