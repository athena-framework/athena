# Stores metadata associated with a specific property.
module Athena::Validator::Metadata::PropertyMetadataInterface
  include Athena::Validator::Metadata::MetadataInterface

  # Returns the name of the member represented by `self`.
  abstract def name : String

  # Returns the value of the member represented by `self.
  protected abstract def value(obj : ADVD::Valdatable)
end
