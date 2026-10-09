require "./spec_helper"

struct NativeQueryTest < ASPEC::TestCase
  @connection : MockConnection
  @em : MockEntityManager

  def initialize
    @connection = MockConnection.new
    @em = MockEntityManager.new @connection
  end

  def test_binds_parameters_converted_through_an_explicit_type : Nil
    query = self.build_query "SELECT r.id FROM rot13_items r WHERE r.secret = ?"
    query.set_parameter 1, "hello", Rot13Type::NAME

    @connection.queue_result [] of Hash(String, DB::Any)
    query.get_result

    @connection.executed_statements.last[1].should eq ["uryyb"]
  end

  # Without an explicit type, one is inferred from the value so it converts the same way an entity field would.
  def test_binds_parameters_converted_through_an_inferred_type : Nil
    query = self.build_query "SELECT r.id FROM rot13_items r WHERE r.created_at > ?"
    query.set_parameter 1, Time.local(2016, 1, 1, 15, 58, 59, location: Time::Location.fixed(-5 * 3600))

    @connection.queue_result [] of Hash(String, DB::Any)
    query.get_result

    @connection.executed_statements.last[1].first.as(Time).utc?.should be_true
  end

  def test_binds_positional_parameters_in_position_order : Nil
    query = self.build_query "SELECT r.id FROM rot13_items r WHERE r.id = ? AND r.secret = ?"
    query.set_parameter 2, "second"
    query.set_parameter 1, "first"

    @connection.queue_result [] of Hash(String, DB::Any)
    query.get_result

    @connection.executed_statements.last[1].should eq ["first", "second"]
  end

  private def build_query(sql : String) : AORM::NativeQuery
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result Rot13Item, "r"
    rsm.add_field_result "r", "id", "id"

    @em.create_native_query sql, rsm
  end
end
