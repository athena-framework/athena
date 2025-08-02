require "../spec_helper"
require "./file_validator_test_case"

private alias CONSTRAINT = AVD::Constraints::File

struct FileValidatorStdlibFileTest < FileValidatorTestCase
  protected def get_file(file_path : String)
    ::File.new file_path
  end
end
