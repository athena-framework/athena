require "./platform"

# Base platform for MySQL-like platforms.
#
# Connections from the `mysql` driver shard use `AORM::Platforms::Maria` or `AORM::Platforms::MySQL`, depending on whether the driver reports the server as MariaDB (`DB::Connection#server_name`).
#
# Identifiers are quoted with backticks.
abstract class Athena::ORM::Platforms::AbstractMySQL < Athena::ORM::Platforms::Platform
  # :inherit:
  #
  # MySQL and MariaDB wrap identifiers in backticks instead, with any embedded backticks doubled.
  def quote_single_identifier(identifier : String) : String
    "`#{identifier.gsub('`', "``")}`"
  end

  # :inherit:
  def boolean_type_declaration_sql(column : Schema::Column) : String
    "TINYINT"
  end

  # :inherit:
  def small_int_type_declaration_sql(column : Schema::Column) : String
    "SMALLINT#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def integer_type_declaration_sql(column : Schema::Column) : String
    "INTEGER#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def big_int_type_declaration_sql(column : Schema::Column) : String
    "BIGINT#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def float_declaration_sql(column : Schema::Column) : String
    "DOUBLE PRECISION#{self.unsigned_declaration column}"
  end

  # :inherit:
  def small_float_declaration_sql(column : Schema::Column) : String
    "FLOAT#{self.unsigned_declaration column}"
  end

  # :inherit:
  def decimal_type_declaration_sql(column : Schema::Column) : String
    "#{super}#{self.unsigned_declaration column}"
  end

  # :inherit:
  def date_time_type_declaration_sql(column : Schema::Column) : String
    "DATETIME"
  end

  # :inherit:
  def blob_type_declaration_sql(column : Schema::Column) : String
    if length = column.length
      return "TINYBLOB" if length <= 255
      return "BLOB" if length <= 65_535
      return "MEDIUMBLOB" if length <= 16_777_215
    end

    "LONGBLOB"
  end

  private def common_integer_type_declaration_sql(column : Schema::Column) : String
    sql = self.unsigned_declaration column

    if column.auto_increment?
      sql = "#{sql} AUTO_INCREMENT"
    end

    sql
  end
end
