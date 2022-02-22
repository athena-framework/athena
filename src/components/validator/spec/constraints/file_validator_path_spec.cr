require "../spec_helper"
require "./file_validator_test_case"

@[ASPEC::TestCase::Focus]
struct FileValidatorTest < FileValidatorTestCase
  protected def get_file(file_path : String)
    file_path
  end
end
