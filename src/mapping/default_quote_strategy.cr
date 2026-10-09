require "./quote_strategy_interface"

# The quote strategy used for every entity.
#
# Names aren't quoted automatically, since quoting can change which table or column a name refers to.
# For example, PostgreSQL folds unquoted names to lower case, but matches quoted ones exactly.
# Instead, quoting is opted into per name by wrapping it in backticks in the mapping.
# The name is then quoted in every statement, using the quoting of the database platform: `` `groups` `` on MySQL and MariaDB, `"groups"` on PostgreSQL and SQLite.
#
# ```
# # `groups` is a reserved word on MySQL.
# @[AORMA::Entity]
# @[AORMA::Table(name: "`groups`")]
# class Group < AORM::Entity
#   @[AORMA::Column(name: "`order`")]
#   property! order : Int32
#
#   # ...
# end
# ```
#
# Backticks are supported in the names of tables (`AORMA::Table`), columns (`AORMA::Column`), join tables (`AORMA::JoinTable`), and join columns (`AORMA::JoinColumn` and `AORMA::InverseJoinColumn`, both `name` and `referenced_column_name`).
struct Athena::ORM::Mapping::DefaultQuoteStrategy
  include Athena::ORM::Mapping::QuoteStrategyInterface

  # Returns the column names of the identifier fields of *class_metadata*, quoted if needed.
  def identifier_column_names(class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : Array(String)
    quoted_column_names = [] of String

    class_metadata.identifier.each do |field_name|
      if class_metadata.field_mappings.has_key?(field_name)
        quoted_column_names << self.column_name field_name, class_metadata, platform

        next
      end

      # TODO: Handle associations
    end

    quoted_column_names
  end

  # Returns the table name of *class_metadata*, quoted if needed.
  def table_name(class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : String
    table = class_metadata.table
    table_name = table.name.not_nil!

    if schema = table.schema.presence
      return table.quoted ? "#{platform.quote_single_identifier schema}.#{platform.quote_single_identifier table_name}" : "#{schema}.#{table_name}"
    end

    table.quoted ? platform.quote_single_identifier(table_name) : table_name
  end

  # Returns the join table name of *association*.
  def join_table_name(association : Mapping::ManyToManyOwningSide, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : String
    join_table = association.join_table.not_nil!

    schema = ""

    if sch = join_table.schema.presence
      schema = "#{sch}."
    end

    table_name = join_table.name

    if join_table.quoted?
      table_name = platform.quote_single_identifier table_name
    end

    "#{schema}#{table_name}"
  end

  # Returns the name of the column *join_column* references, quoted if needed.
  def referenced_join_column_name(join_column : Mapping::JoinColumn, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : String
    join_column.quoted ? platform.quote_single_identifier(join_column.referenced_column_name) : join_column.referenced_column_name
  end

  # Returns the name of *join_column*, quoted if needed.
  def join_column_name(join_column : Mapping::JoinColumn, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : String
    join_column.quoted ? platform.quote_single_identifier(join_column.name) : join_column.name
  end

  # Returns the column name of the field named *field_name* of *class_metadata*, quoted if needed.
  def column_name(field_name : String, class_metadata : Mapping::ClassInterface, platform : Platforms::Platform) : String
    fm = class_metadata.field_mappings[field_name]

    fm.quoted ? platform.quote_single_identifier(fm.column_name) : fm.column_name
  end

  # Returns a unique result column alias for *column_name*, valid on *platform*.
  def column_alias(column_name : String, counter : Int, platform : Platforms::Platform, class_metadata : Mapping::ClassInterface? = nil) : String
    # 1. Concat name and counter
    # 2. Trim alias to max length allowed by platform, trimming from beginning if needed
    # 3. Strip non alphanumeric characters
    # 4. Prefix with `_` if numeric
    column_name = "#{column_name}_#{counter}"
    column_name = column_name[-{platform.max_identifier_length, column_name.size}.min..]
    column_name = column_name.gsub /[^A-Za-z0-9_]/, ""
    column_name = column_name.to_i? ? "_#{column_name}" : column_name

    self.sql_result_casing platform, column_name
  end
end
