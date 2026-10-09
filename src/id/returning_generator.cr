require "./abstract_generator"
require "./row_consuming_generator"

# :nodoc:
struct Athena::ORM::ID::ReturningGenerator < Athena::ORM::ID::AbstractGenerator
  include Athena::ORM::ID::RowConsumingGenerator

  # :inherit:
  def generate(em : AORM::EntityManagerInterface, entity : AORM::Entity? = nil)
    raise "BUG: ReturningGenerator#generate should not be called; ids are read from the INSERT result row via #consume_row"
  end

  # :inherit:
  def post_insert? : Bool
    true
  end

  # :inherit:
  def consume_row(rs : DB::ResultSet, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : Hash(String, Mapping::Value)
    id_hash = Hash(String, Mapping::Value).new

    class_metadata.identifier.each do |field_name|
      column_type = class_metadata.field_mappings[field_name].type
      id_hash[field_name] = Mapping::SingleValue.new AORM::Types::Type.get_type(column_type).read_value(rs, platform)
    end

    id_hash
  end
end
