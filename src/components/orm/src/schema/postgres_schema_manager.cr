require "./abstract_schema_manager"

# The schema manager of `AORM::Platforms::Postgres`.
class Athena::ORM::Schema::PostgresSchemaManager < Athena::ORM::Schema::AbstractSchemaManager
  protected def determine_current_schema_name : String?
    @connection.fetch_one("SELECT current_schema()").as(String)
  end
end
