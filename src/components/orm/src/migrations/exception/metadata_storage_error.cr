# Raised when the metadata storage is used before it's ready, see `AORM::Migrations::Metadata::Storage::Interface#ensure_initialized`.
class Athena::ORM::Migrations::Exception::MetadataStorageError < RuntimeError
  include Athena::ORM::Migrations::Exception

  def self.not_initialized : self
    new "The metadata storage is not initialized, please run the sync-metadata-storage command to fix this issue."
  end
end
