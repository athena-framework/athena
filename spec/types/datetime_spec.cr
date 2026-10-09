require "../spec_helper"

struct DatetimeTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Datetime

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Datetime.new
  end

  def test_sql_declaration_is_the_platforms_date_time_declaration : Nil
    column = AORM::Schema::Column.new "c", @type
    @type.sql_declaration(column, AORM::Platforms::Postgres.new).should eq "TIMESTAMP(0) WITHOUT TIME ZONE"
  end

  # Columns store UTC wall-clock time, so a time in any other location must be shifted before binding.
  def test_converts_non_utc_time_to_utc_db_value : Nil
    time = Time.local 2016, 1, 1, 15, 58, 59, location: Time::Location.fixed(-5 * 3600)

    db_value = @type.to_db(time, @platform).as(Time)

    db_value.utc?.should be_true
    db_value.should eq Time.utc(2016, 1, 1, 20, 58, 59)
  end

  def test_does_not_mutate_the_given_time : Nil
    location = Time::Location.fixed(-5 * 3600)
    time = Time.local 2016, 1, 1, 15, 58, 59, location: location

    @type.to_db time, @platform

    time.location.should eq location
    time.hour.should eq 15
  end

  def test_converts_nil_to_db_value : Nil
    @type.to_db(nil, @platform).should be_nil
  end

  def test_converts_db_string_to_utc_time : Nil
    time = @type.to_crystal_value("2016-01-01 20:58:59", @platform).not_nil!

    time.utc?.should be_true
    time.should eq Time.utc(2016, 1, 1, 20, 58, 59)
  end

  def test_converts_nil_to_crystal_value : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_passes_time_through_unchanged : Nil
    time = Time.utc 2016, 1, 1, 20, 58, 59

    @type.to_crystal_value(time, @platform).should eq time
  end

  def test_raises_for_invalid_datetime_string : Nil
    expect_raises(Time::Format::Error) do
      @type.to_crystal_value("invalid datetime string", @platform)
    end
  end
end
