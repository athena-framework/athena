# :nodoc:
class Athena::ORM::Persisters::Entity::CachedPersisterContext
  @sql_alias_counter = Int64.zero

  getter sql_table_aliases = Hash(String?, String).new
  getter class_metadata : AORM::Mapping::ClassInterface
  getter? handles_limit : Bool

  # Result set mapping built alongside SQL generation
  getter rsm : AORM::Query::ResultSetMapping

  property select_column_list_sql : String? = nil
  property select_join_sql : String = ""

  def initialize(
    @class_metadata : AORM::Mapping::ClassInterface,
    @handles_limit : Bool,
  )
    @rsm = AORM::Query::ResultSetMapping.new
  end

  def sql_alias_counter : Int
    idx = @sql_alias_counter
    @sql_alias_counter += 1
    idx
  end
end
