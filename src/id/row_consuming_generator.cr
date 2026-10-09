# :nodoc:
module Athena::ORM::ID::RowConsumingGenerator
  abstract def consume_row(rs : DB::ResultSet, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : Hash(String, Mapping::Value)
end
