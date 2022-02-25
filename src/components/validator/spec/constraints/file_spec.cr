require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::File

struct FileTest < ASPEC::TestCase
  @[DataProvider("valid_sizes")]
  def test_max_size(max_size : String | Int, bytes : Int, binary_format : Bool) : Nil
    constraint = CONSTRAINT.new max_size: max_size

    constraint.max_size.should eq bytes
    constraint.binary_format?.should eq binary_format
  end

  @[DataProvider("invalid_sizes")]
  def test_invalid_max_size(max_size : String | Int) : Nil
    expect_raises ArgumentError do
      CONSTRAINT.new max_size: max_size
    end
  end

  @[DataProvider("formats")]
  def test_binary_format(max_size : String | Int, guessed_format : Bool?, binary_format : Bool) : Nil
    CONSTRAINT.new(max_size: max_size, binary_format: guessed_format).binary_format?.should eq binary_format
  end

  def valid_sizes : Tuple
    {
      {"500", 500, false},
      {12_300, 12_300, false},
      {"1ki", 1_024, true},
      {"1KI", 1_024, true},
      {"2k", 2_000, false},
      {"2K", 2_000, false},
      {"1mi", 1_048_576, true},
      {"1MI", 1_048_576, true},
      {"3m", 3_000_000, false},
      {"3M", 3_000_000, false},
      {"1gi", 1_073_741_824, true},
      {"1GI", 1_073_741_824, true},
      {"4g", 4_000_000_000, false},
      {"4G", 4_000_000_000, false},
    }
  end

  def invalid_sizes : Tuple
    {
      {"foo"},
      {"1Ko"},
      {"1kio"},
    }
  end

  def formats : Tuple
    {
      {100, nil, false},
      {100, true, true},
      {100, false, false},
      {"100K", nil, false},
      {"100K", true, true},
      {"100K", false, false},
      {"100Ki", nil, true},
      {"100Ki", true, true},
      {"100Ki", false, false},
    }
  end
end
