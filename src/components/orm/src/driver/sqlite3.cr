require "../driver"

# The `sqlite3` driver shard ([crystal-lang/crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3)), using `AORM::Platforms::SQLite`.
struct Athena::ORM::Driver::SQLite3 < Athena::ORM::Driver
  # :inherit:
  def database_platform(connection : DB::Connection) : Platforms::Platform
    Platforms::SQLite.new
  end
end
