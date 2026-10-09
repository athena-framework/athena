require "./driver/*"

# Picks the `AORM::Driver` adapting connections from each supported `crystal-db` driver shard:
#
# | Driver name | Driver shard                                                                    | Driver                    |
# | ----------- | ------------------------------------------------------------------------------- | ------------------------- |
# | `postgres`  | [will/crystal-pg](https://github.com/will/crystal-pg)                           | `AORM::Driver::Postgres`  |
# | `mysql`     | [crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql)     | `AORM::Driver::MySQL`     |
# | `sqlite3`   | [crystal-lang/crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) | `AORM::Driver::SQLite3`   |
module Athena::ORM::DriverManager
  # The driver for each driver shard, keyed by the name the shard registers its connections with (`DB::Connection#driver_name`).
  DRIVER_MAP = {
    "postgres" => AORM::Driver::Postgres,
    "mysql"    => AORM::Driver::MySQL,
    "sqlite3"  => AORM::Driver::SQLite3,
  }

  # Returns the driver adapting *connection*'s driver shard.
  #
  # Raises `AORM::Exceptions::UnknownDriver` if the ORM doesn't support it.
  def self.driver(connection : DB::Connection) : AORM::Driver
    driver_name = connection.driver_name
    driver_class = DRIVER_MAP[driver_name]? || raise Exceptions::UnknownDriver.new driver_name, DRIVER_MAP.keys

    driver_class.new
  end
end
