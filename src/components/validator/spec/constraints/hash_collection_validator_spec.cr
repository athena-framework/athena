require "../spec_helper"
require "./collection_validator_test_case"

struct HashCollectionValidatorTest < CollectionValidatorTestCase
  private def prepare_test_data(contents : Hash)
    contents
  end
end
