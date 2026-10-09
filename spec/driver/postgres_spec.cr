require "../spec_helper"

struct DriverPostgresTest < ASPEC::TestCase
  @connection : MockConnection = MockConnection.new driver_name: "postgres"
  @driver : AORM::Driver = AORM::Driver::Postgres.new

  def test_platform : Nil
    @driver.database_platform(@connection).should be_a AORM::Platforms::Postgres
  end

  def test_prepare_numbers_placeholders : Nil
    @driver.prepare @connection, "SELECT * FROM t WHERE a = ? AND b = ?"

    @connection.built_statements.last.should eq "SELECT * FROM t WHERE a = $1 AND b = $2"
  end

  # A `?` in a string literal isn't a placeholder.
  def test_prepare_leaves_question_marks_in_string_literals : Nil
    @driver.prepare @connection, "SELECT '?' FROM t WHERE a = ?"

    @connection.built_statements.last.should eq "SELECT '?' FROM t WHERE a = $1"
  end

  # The driver shard doesn't report generated identifiers.
  def test_last_insert_id_asks_the_server_for_the_last_sequence_value : Nil
    @connection.queue_result [{"lastval" => 9_i64} of String => DB::Any]

    @driver.last_insert_id(@connection, 0_i64).should eq 9
    @connection.executed_statements.last.should eq({"SELECT LASTVAL()", [] of DB::Any})
  end
end
