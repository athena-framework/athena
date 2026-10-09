require "../spec_helper"

struct DriverMySQLTest < ASPEC::TestCase
  @[DataProvider("servers")]
  def test_platform_is_picked_by_the_server(server_name : String?, platform : AORM::Platforms::AbstractMySQL.class) : Nil
    AORM::Driver::MySQL.new.database_platform(MockConnection.new driver_name: "mysql", server_name: server_name).class.should eq platform
  end

  def servers : Hash
    {
      "MySQL"          => {"MySQL", AORM::Platforms::MySQL},
      "MariaDB"        => {"MariaDB", AORM::Platforms::Maria},
      "unknown server" => {nil, AORM::Platforms::MySQL},
    }
  end
end
