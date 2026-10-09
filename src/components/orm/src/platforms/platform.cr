# Describes the SQL dialect and capabilities of a database, such as how identifiers are quoted, how column types are declared, and whether `INSERT ... RETURNING` is supported.
#
# The platform is determined from the driver connection an `AORM::EntityManager` is created with, and is available via `AORM::Connection#database_platform`:
#
# | Driver shard | Platform |
# | ------------ | -------- |
# | `pg` | `AORM::Platforms::Postgres` |
# | `mysql` | `AORM::Platforms::MySQL` or `AORM::Platforms::Maria`, depending on the server's version string |
# | `sqlite3` | `AORM::Platforms::SQLite` |
#
# NOTE: Connections of any other driver aren't supported, and creating an entity manager on one raises `NotImplementedError`.
abstract class Athena::ORM::Platforms::Platform
  # Returns *identifier* quoted for use as a table or column name.
  #
  # By default, identifiers are wrapped in double quotes, with any embedded double quotes doubled.
  def quote_single_identifier(identifier : String) : String
    %("#{identifier.gsub('"', "\"\"")}")
  end

  # Returns the `Time::Format` pattern used to parse date and time values that a driver returns as strings.
  def date_time_format_string : String
    "%F %T"
  end

  # Returns *from_clause* with the hint that applies *lock_mode* to the rows it selects.
  #
  # TODO: Row locking isn't supported yet, so this returns *from_clause* unchanged.
  def append_lock_hint(from_clause : String, lock_mode : LockMode) : String
    from_clause
  end

  # Returns *sql* with clauses limiting its result to *limit* rows, skipping the first *offset* rows.
  #
  # Raises if *offset* is negative.
  def modify_limit_query(sql : String, limit : Int?, offset : Int = 0) : String
    if offset < 0
      raise "Offset must be a positive integer or zero, #{offset} given."
    end

    self.do_modify_limit_query sql, limit, offset
  end

  protected def do_modify_limit_query(sql : String, limit : Int?, offset : Int) : String
    sql += " LIMIT #{limit}" if limit
    sql += " OFFSET #{offset}" if offset && offset > 0

    sql
  end

  # Returns the SQL that fetches the next value of the sequence named *sequence_name*.
  #
  # Raises `NotImplementedError` on platforms without sequences.
  def sequence_next_value_sql(sequence_name : String) : String
    raise NotImplementedError.new {{@def.name.stringify}}
  end

  # Returns the SQL that inserts a row into *quoted_table_name* without values for any column, letting the database generate *quoted_identifier_column_name*.
  def empty_identity_insert_sql(quoted_table_name : String, quoted_identifier_column_name) : String
    "INSERT INTO #{quoted_table_name} (#{quoted_identifier_column_name}) VALUES (null)"
  end

  # Returns `true` if `INSERT` statements can return values of the inserted row via a `RETURNING` clause.
  #
  # Database-generated identifiers are read from that clause when supported, and from the driver's last insert id otherwise.
  # Only the latter is limited to a single identifier column.
  def supports_returning? : Bool
    false
  end

  # Returns the keyword that introduces the columns an `INSERT` returns.
  def returning_keyword_sql : String
    "RETURNING"
  end

  # Converts *value* into the value bound for a boolean column.
  # Returns it unchanged by default.
  #
  # Raises if *value* isn't a `Bool`, `nil`, or an `Array(Bool)`.
  def convert_booleans_to_db_value(value : Bool?) : Bool?
    # Passthrough by default: the underlying driver binds `Bool` natively against boolean columns (Postgres `BOOLEAN`, SQLite stored as `INTEGER 0/1`), so there's no value conversion to do at this layer.
    value
  end

  # :ditto:
  def convert_booleans_to_db_value(value : Array(Bool)) : Array(Bool)
    value
  end

  # :ditto:
  def convert_booleans_to_db_value(value : _)
    raise "#{self.class} cannot convert #{value.class} to a boolean DB value"
  end

  # Converts *value*, as read from a boolean column, into a `Bool`, or `nil` for a `NULL` value.
  #
  # Integers are `true` unless they're `0`.
  # Raises if *value* can't be converted.
  def convert_from_boolean(value : Nil) : Nil
    nil
  end

  # :ditto:
  def convert_from_boolean(value : Bool) : Bool
    value
  end

  # :ditto:
  def convert_from_boolean(value : Int) : Bool
    # SQLite stores booleans as `INTEGER 0/1`; map back to `Bool` here.
    # Crystal's `!!0` is `true` (only `nil`/`false` are falsy), so a literal `(bool)$value` port would silently convert `0` to `true` — explicit numeric comparison is required.
    value != 0
  end

  # :ditto:
  def convert_from_boolean(value : _) : Bool
    raise "#{self.class} cannot convert #{value.class} to Bool"
  end

  # SQL Declarations

  # Returns the SQL declaring *column* as a string column, e.g. `VARCHAR(255)`, or `CHAR(2)` for a fixed-length column.
  #
  # Raises if a variable-length *column* has no length, on platforms that require one.
  def string_type_declaration_sql(column : Schema::Column) : String
    length = column.length

    unless column.fixed?
      return self.varchar_type_declaration_sql length
    end

    self.char_type_declaration_sql length
  end

  # Returns the SQL declaring *column* as a UUID column.
  #
  # Platforms without a native UUID type declare a 36 character fixed-length string column.
  def guid_type_declaration_sql(column : Schema::Column) : String
    column.length = 36
    column.fixed = true

    self.string_type_declaration_sql column
  end

  # Returns the SQL declaring *column* as a boolean column.
  abstract def boolean_type_declaration_sql(column : Schema::Column) : String
  # Returns the SQL declaring *column* as a small (2 byte) integer column.
  abstract def small_int_type_declaration_sql(column : Schema::Column) : String
  # Returns the SQL declaring *column* as an integer (4 byte) column.
  abstract def integer_type_declaration_sql(column : Schema::Column) : String
  # Returns the SQL declaring *column* as a big (8 byte) integer column.
  abstract def big_int_type_declaration_sql(column : Schema::Column) : String
  # Returns the SQL declaring *column* as a binary large object column.
  abstract def blob_type_declaration_sql(column : Schema::Column) : String

  # Returns the SQL declaring *column* as a date and time column without a time zone.
  abstract def date_time_type_declaration_sql(column : Schema::Column) : String

  # Returns the SQL declaring *column* as a double precision floating point column.
  def float_declaration_sql(column : Schema::Column) : String
    "DOUBLE PRECISION"
  end

  # Returns the SQL declaring *column* as a single precision floating point column.
  def small_float_declaration_sql(column : Schema::Column) : String
    "REAL"
  end

  # Returns the SQL declaring *column* as an exact numeric column, e.g. `NUMERIC(10, 2)`.
  #
  # Raises if *column* has no precision or scale.
  def decimal_type_declaration_sql(column : Schema::Column) : String
    raise "Precision required" unless precision = column.precision
    raise "Scale required" unless scale = column.scale

    "NUMERIC(#{precision}, #{scale})"
  end

  # Returns the SQL declaring *column* as a fixed or variable-length binary column, e.g. `VARBINARY(16)`.
  #
  # Raises if a variable-length *column* has no length.
  def binary_type_declaration_sql(column : Schema::Column) : String
    column.fixed? ? self.binary_type_declaration_sql_snippet(column.length) : self.varbinary_type_declaration_sql_snippet(column.length)
  end

  protected def binary_type_declaration_sql_snippet(length : Int32?) : String
    length ? "BINARY(#{length})" : "BINARY"
  end

  protected def varbinary_type_declaration_sql_snippet(length : Int32?) : String
    raise "Length required" unless length

    "VARBINARY(#{length})"
  end

  protected def unsigned_declaration(column : Schema::Column) : String
    column.unsigned? ? " UNSIGNED" : ""
  end

  private abstract def common_integer_type_declaration_sql(column : Schema::Column) : String

  private def varchar_type_declaration_sql(length : Int32?) : String
    raise "Length required" unless length

    "VARCHAR(#{length})"
  end

  private def char_type_declaration_sql(length : Int32?) : String
    length ? "CHAR(#{length})" : "CHAR"
  end

  # Limits / Constants

  # Returns the maximum length of any given database identifier, like tables or column names.
  def max_identifier_length : Int32
    63
  end
end
