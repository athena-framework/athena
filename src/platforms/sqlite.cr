# Base platform for SQLite.
#
# Database-generated identifiers are read back with `INSERT ... RETURNING`.
class Athena::ORM::Platforms::SQLite < Athena::ORM::Platforms::Platform
  # :inherit:
  def boolean_type_declaration_sql(column : Schema::Column) : String
    "BOOLEAN"
  end

  # :inherit:
  def small_int_type_declaration_sql(column : Schema::Column) : String
    # SQLite autoincrement is implicit for INTEGER PKs, but not for SMALLINT fields.
    if column.auto_increment?
      return self.integer_type_declaration_sql column
    end

    "SMALLINT#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def integer_type_declaration_sql(column : Schema::Column) : String
    "INTEGER#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def big_int_type_declaration_sql(column : Schema::Column) : String
    # SQLite autoincrement is implicit for INTEGER PKs, but not for BIGINT fields.
    if column.auto_increment?
      return self.integer_type_declaration_sql column
    end

    "BIGINT#{self.common_integer_type_declaration_sql column}"
  end

  # :inherit:
  def blob_type_declaration_sql(column : Schema::Column) : String
    "BLOB"
  end

  # :inherit:
  def date_time_type_declaration_sql(column : Schema::Column) : String
    "DATETIME"
  end

  # A length is optional for `VARCHAR` columns on SQLite.
  private def varchar_type_declaration_sql(length : Int32?) : String
    length ? "VARCHAR(#{length})" : "VARCHAR"
  end

  protected def binary_type_declaration_sql_snippet(length : Int32?) : String
    "BLOB"
  end

  protected def varbinary_type_declaration_sql_snippet(length : Int32?) : String
    "BLOB"
  end

  private def common_integer_type_declaration_sql(column : Schema::Column) : String
    if column.auto_increment?
      return " PRIMARY KEY AUTOINCREMENT"
    end

    column.unsigned? ? " UNSIGNED" : ""
  end

  protected def do_modify_limit_query(sql : String, limit : Int?, offset : Int) : String
    if limit.nil? && offset > 0
      limit = -1
    end

    super sql, limit, offset
  end

  # :inherit:
  def supports_returning? : Bool
    true
  end
end
