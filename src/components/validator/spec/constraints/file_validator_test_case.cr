require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::File

abstract struct FileValidatorTestCase < AVD::Spec::ConstraintValidatorTestCase
  @file : File

  def initialize
    super

    @file = File.open Path[Dir.tempdir, "file_validator_test"], "w"
    @file.print " "
    @file.flush
  end

  def tear_down : Nil
    super

    @file.delete
  end

  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_blank_is_valid : Nil
    self.validator.validate "", self.new_constraint
    self.assert_no_violation
  end

  def test_valid_file : Nil
    self.validator.validate @file.path, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("max_size_exceeded")]
  def test_max_size_exceeded(bytes_written : Int, limit : Int | String, size_as_string : String, limit_as_string : String, suffix : String) : Nil
    self.write_bytes bytes_written
    self.validator.validate self.get_file(@file.path), self.new_constraint max_size: limit, max_size_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LARGE_ERROR)
      .add_parameter("{{ limit }}", limit_as_string)
      .add_parameter("{{ size }}", size_as_string)
      .add_parameter("{{ suffix }}", suffix)
      .add_parameter("{{ file }}", @file.path)
      .add_parameter("{{ name }}", File.basename @file.path)
      .assert_violation
  end

  def max_size_exceeded : Tuple
    {
      # Limit in bytes
      {1_001, 1_000, "1001.0", "1000.0", "bytes"},
      {1_004, 1_000, "1004.0", "1000.0", "bytes"},
      # {1005, 1000, "1.01", "1.0", "kB"},
      {1_006, 1_000, "1.01", "1.0", "kB"},

      {1_000_001, 1_000_000, "1000001.0", "1000000.0", "bytes"},
      {1_004_999, 1_000_000, "1005.0", "1000.0", "kB"},
      # {1_005_000, 1_000_000, "1.01", "1.0", "MB"},
      {1_006_000, 1_000_000, "1.01", "1.0", "MB"},

      # Limit in kB
      {1_001, "1k", "1001.0", "1000.0", "bytes"},
      {1_004, "1k", "1004.0", "1000.0", "bytes"},
      # {1005, "1k", "1.01", "1.0", "kB"},
      {1_006, "1k", "1.01", "1.0", "kB"},

      {1_000_001, "1000k", "1000001.0", "1000000.0", "bytes"},
      {1_004_999, "1000k", "1005.0", "1000.0", "kB"},
      # {1_005_000, "1000k", "1.01", "1.0", "MB"},
      {1_006_000, "1000k", "1.01", "1.0", "MB"},

      # Limit in MB
      {1_000_001, "1M", "1000001.0", "1000000.0", "bytes"},
      {1_004_999, "1M", "1005.0", "1000.0", "kB"},
      # {1_005_000, "1M", "1.01", "1.0", "MB"},
      {1_006_000, "1M", "1.01", "1.0", "MB"},

      # Limit in KiB
      {1_025, "1Ki", "1025.0", "1024.0", "bytes"},
      {1_029, "1Ki", "1029.0", "1024.0", "bytes"},
      {1_030, "1Ki", "1.01", "1.0", "KiB"},

      {1_048_577, "1024Ki", "1048577.0", "1048576.0", "bytes"},
      {1_053_818, "1024Ki", "1029.12", "1024.0", "KiB"},
      {1_053_819, "1024Ki", "1.01", "1.0", "MiB"},

      # Limit in MiB
      {1_048_577, "1Mi", "1048577.0", "1048576.0", "bytes"},
      {1_053_818, "1Mi", "1029.12", "1024.0", "KiB"},
      {1_053_819, "1Mi", "1.01", "1.0", "MiB"},
    }
  end

  @[DataProvider("max_size_not_exceeded")]
  def test_max_size_exceeded(bytes_written : Int, limit : Int | String) : Nil
    self.write_bytes bytes_written
    self.validator.validate self.get_file(@file.path), self.new_constraint max_size: limit, max_size_message: "my_message"
    self.assert_no_violation
  end

  def max_size_not_exceeded : Tuple
    {
      # Limit in bytes
      {1_000, 1_000},
      {1_000_000, 1_000_000},

      # Limit in kB
      {1_000, "1k"},
      {1_000_000, "1000k"},

      # Limit in MB
      {1_000_000, "1M"},

      # Limit in KiB
      {1_024, "1Ki"},
      {1_048_576, "1024Ki"},

      # Limit in MiB
      {1_048_576, "1Mi"},
    }
  end

  @[DataProvider("max_size_exceeded_binary_format")]
  def test_max_size_exceeded(bytes_written : Int, limit : Int | String, binary_format : Bool?, size_as_string : String, limit_as_string : String, suffix : String) : Nil
    self.write_bytes bytes_written
    self.validator.validate self.get_file(@file.path), self.new_constraint max_size: limit, binary_format: binary_format, max_size_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LARGE_ERROR)
      .add_parameter("{{ limit }}", limit_as_string)
      .add_parameter("{{ size }}", size_as_string)
      .add_parameter("{{ suffix }}", suffix)
      .add_parameter("{{ file }}", @file.path)
      .add_parameter("{{ name }}", File.basename @file.path)
      .assert_violation
  end

  def max_size_exceeded_binary_format : Tuple
    {
      {11, 10, nil, "11.0", "10.0", "bytes"},
      {11, 10, true, "11.0", "10.0", "bytes"},
      {11, 10, false, "11.0", "10.0", "bytes"},

      {1_010, 1000, nil, "1.01", "1.0", "kB"},
      {1_010, "1k", nil, "1.01", "1.0", "kB"},
      {1_035, "1Ki", nil, "1.01", "1.0", "KiB"},

      {1_035, 1024, true, "1.01", "1.0", "KiB"},
      {1_034_240, "1024k", true, "1010.0", "1000.0", "KiB"},
      {1_035, "1Ki", true, "1.01", "1.0", "KiB"},

      {1_010, 1000, false, "1.01", "1.0", "kB"},
      {1_010, "1k", false, "1.01", "1.0", "kB"},
      {10_343, "10Ki", false, "10.34", "10.24", "kB"},
    }
  end

  def test_valid_mime_type : Nil
    self.validator.validate Path[__DIR__, "fixtures/foo.png"], self.new_constraint mime_types: {"image/png", "image/jpeg"}
    self.assert_no_violation
  end

  def test_valid_wildcard_mime_type : Nil
    self.validator.validate Path[__DIR__, "fixtures/foo.png"], self.new_constraint mime_types: {"image/*"}
    self.assert_no_violation
  end

  def test_invalid_mime_type : Nil
    File.copy Path[__DIR__, "fixtures/foo.png"], dest_path = Path[Dir.tempdir, "/file_validator_test.png"]

    self.validator.validate self.get_file(dest_path.to_s), self.new_constraint mime_types: {"application/pdf"}, mime_type_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::INVALID_MIME_TYPE_ERROR)
      .add_parameter("{{ type }}", "image/png")
      .add_parameter("{{ types }}", %(Set{"application/pdf"}))
      .add_parameter("{{ file }}", dest_path)
      .add_parameter("{{ name }}", "file_validator_test.png")
      .assert_violation
  end

  def test_invalid_wildcard_mime_type : Nil
    File.copy Path[__DIR__, "fixtures/foo.png"], dest_path = Path[Dir.tempdir, "/file_validator_test.png"]

    self.validator.validate self.get_file(dest_path.to_s), self.new_constraint mime_types: {"application/*"}, mime_type_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::INVALID_MIME_TYPE_ERROR)
      .add_parameter("{{ type }}", "image/png")
      .add_parameter("{{ types }}", %(Set{"application/*"}))
      .add_parameter("{{ file }}", dest_path)
      .add_parameter("{{ name }}", "file_validator_test.png")
      .assert_violation
  end

  def test_empty_file : Nil
    @file.truncate

    self.validator.validate self.get_file(@file.path), self.new_constraint empty_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::EMPTY_ERROR)
      .add_parameter("{{ file }}", @file.path)
      .add_parameter("{{ name }}", File.basename @file.path)
      .assert_violation
  end

  protected abstract def get_file(file_path : String)

  private def write_bytes(bytes : Int) : Nil
    @file.write Random.new.random_bytes bytes - 1
    @file.flush
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
