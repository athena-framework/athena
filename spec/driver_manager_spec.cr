require "./spec_helper"

struct DriverManagerTest < ASPEC::TestCase
  @[DataProvider("drivers")]
  def test_driver_is_picked_by_the_connections_driver_name(driver_name : String, driver : AORM::Driver.class, platform : AORM::Platforms::Platform.class) : Nil
    connection = MockConnection.new driver_name: driver_name
    picked = AORM::DriverManager.driver connection

    picked.class.should eq driver
    picked.database_platform(connection).class.should eq platform
  end

  def drivers : Hash
    {
      "postgres" => {"postgres", AORM::Driver::Postgres, AORM::Platforms::Postgres},
      "mysql"    => {"mysql", AORM::Driver::MySQL, AORM::Platforms::MySQL},
      "sqlite3"  => {"sqlite3", AORM::Driver::SQLite3, AORM::Platforms::SQLite},
    }
  end

  def test_unknown_driver_raises : Nil
    expect_raises AORM::Exceptions::UnknownDriver, %(The given driver "oracle" is unknown, the ORM currently supports only the following drivers: postgres, mysql, sqlite3.) do
      AORM::DriverManager.driver MockConnection.new(driver_name: "oracle")
    end
  end
end
