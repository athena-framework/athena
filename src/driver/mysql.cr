require "../driver"

# The `mysql` driver shard ([crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql)), which connects to MySQL and MariaDB.
#
# MariaDB servers use `AORM::Platforms::Maria`, and other servers use `AORM::Platforms::MySQL`.
struct Athena::ORM::Driver::MySQL < Athena::ORM::Driver
  # :inherit:
  def database_platform(connection : DB::Connection) : Platforms::Platform
    connection.server_name == "MariaDB" ? Platforms::Maria.new : Platforms::MySQL.new
  end
end
