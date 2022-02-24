require "../spec_helper"
require "./file_validator_test_case"

private alias CONSTRAINT = AVD::Constraints::File

struct FileValidatorPathTest < FileValidatorTestCase
  def test_not_found : Nil
    self.validator.validate "foo", self.new_constraint not_found_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_FOUND_ERROR)
      .add_parameter("{{ file }}", "foo")
      .assert_violation
  end

  protected def get_file(file_path : String)
    file_path
  end
end
