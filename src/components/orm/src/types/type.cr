# Contains the types that convert values between their Crystal and database representations, and the names they're registered under.
# See `AORM::Types::Type` for more information.
module Athena::ORM::Types
  # Name of the `AORM::Types::BigInt` type.
  BIGINT = "bigint"

  # Name of the `AORM::Types::Binary` type.
  BINARY = "binary"

  # Name of the `AORM::Types::Blob` type.
  BLOB = "blob"

  # Name of the `AORM::Types::Boolean` type.
  BOOLEAN = "boolean"

  # Name of the `AORM::Types::Datetime` type.
  DATETIME = "datetime"

  # Name of the `AORM::Types::Decimal` type.
  DECIMAL = "decimal"

  # Name of the `AORM::Types::Float` type.
  FLOAT = "float"

  # Name of the `AORM::Types::Guid` type.
  GUID = "guid"

  # Name of the `AORM::Types::Integer` type.
  INTEGER = "integer"

  # Name of the `AORM::Types::Number` type, which is only registered when the program defines `BigDecimal`.
  NUMBER = "number"

  # Name of the `AORM::Types::SmallFloat` type.
  SMALLFLOAT = "smallfloat"

  # Name of the `AORM::Types::SmallInt` type.
  SMALLINT = "smallint"

  # Name of the `AORM::Types::String` type.
  STRING = "string"

  # An alternative name for the `AORM::Types::String` type.
  TEXT = "text"

  # Converts a mapped field's values between their Crystal representation and their database representation.
  #
  # Every mapped field has a type, identified by its name, such as `"string"` or `"datetime"`.
  # It's inferred from the property's Crystal type, or set explicitly with the `type` argument of `AORMA::Column`.
  # When an entity is loaded, its type converts each column into the value assigned to the property.
  # When an entity is written, its type converts the property's value into something the database driver can bind.
  #
  # ```
  # @[AORMA::Entity]
  # class Product < AORM::Entity
  #   # Mapped as `bigint`, inferred from `Int64`.
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   @[AORMA::GeneratedValue]
  #   property! id : Int64
  #
  #   # Mapped as `decimal`, set explicitly.
  #   @[AORMA::Column(type: "decimal")]
  #   property! price : String
  # end
  # ```
  #
  # ## Built-in Types
  #
  # | Name | Type | Crystal value | Inferred from |
  # | ---- | ---- | ------------- | ------------- |
  # | `string`, `text` | `AORM::Types::String` | `String` | `String` |
  # | `smallint` | `AORM::Types::SmallInt` | `Int16` | `Int16` |
  # | `integer` | `AORM::Types::Integer` | `Int32` | `Int32`, and enums whose base type fits in an `Int32` |
  # | `bigint` | `AORM::Types::BigInt` | `Int64` | `Int64`, and enums based on `Int64`, `UInt32` or `UInt64` |
  # | `smallfloat` | `AORM::Types::SmallFloat` | `Float32` | `Float32` |
  # | `float` | `AORM::Types::Float` | `Float64` | `Float64` |
  # | `decimal` | `AORM::Types::Decimal` | `String` | |
  # | `number` | `AORM::Types::Number` | `BigDecimal` | `BigDecimal` |
  # | `boolean` | `AORM::Types::Boolean` | `Bool` | `Bool` |
  # | `datetime` | `AORM::Types::Datetime` | `Time` | `Time` |
  # | `guid` | `AORM::Types::Guid` | `UUID` | `UUID` |
  # | `binary` | `AORM::Types::Binary` | `Bytes` | |
  # | `blob` | `AORM::Types::Blob` | `Bytes` | `Bytes` |
  #
  # A field whose Crystal type isn't inferred, and that has no explicit `type`, raises when its entity's metadata is built.
  # Enum fields are stored as their member's integer value; see `AORMA::Column` for details.
  #
  # NOTE: The `number` type only exists when the program defines `BigDecimal`, e.g. via `require "big"`, since `BigDecimal` requires linking libgmp.
  #
  # WARNING: MySQL and MariaDB read `DECIMAL` columns as `Float64`, so on those databases `decimal` and `number` values are limited to `Float64` precision and lose their scale, e.g. `"12.3400"` reads back as `"12.34"`.
  # SQLite stores them with `REAL` affinity, with the same limitation.
  # Only Postgres round-trips them exactly.
  #
  # ## Custom Types
  #
  # A custom type can store any Crystal value, such as a value object, in a column.
  # Define a struct inheriting from this type, implementing the conversions in both directions, then register it under a name with `.add_type`.
  #
  # ```
  # # A value object holding an email address.
  # record Email, address : String
  #
  # # Stores an `Email` as its address.
  # struct EmailType < AORM::Types::Type
  #   NAME = "email"
  #
  #   def sql_declaration(column : AORM::Schema::Column, platform : AORM::Platforms::Platform) : String
  #     platform.string_type_declaration_sql column
  #   end
  #
  #   def to_db(value : _, platform : AORM::Platforms::Platform)
  #     value.is_a?(Email) ? value.address : value
  #   end
  #
  #   def to_crystal_value(value : _, platform : AORM::Platforms::Platform) : Email?
  #     case value
  #     when Nil, Email then value
  #     when String     then Email.new value
  #     else                 raise "Cannot convert #{value.class} to an Email."
  #     end
  #   end
  #
  #   def to_crystal_value(value : DB::ResultSet, platform : AORM::Platforms::Platform) : Email?
  #     value.read(String?).try { |address| Email.new address }
  #   end
  # end
  #
  # AORM::Types::Type.add_type EmailType::NAME, EmailType.new
  # ```
  #
  # The type can then be used by passing its name to `AORMA::Column`:
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   @[AORMA::GeneratedValue]
  #   property! id : Int64
  #
  #   @[AORMA::Column(type: "email")]
  #   property! email : Email
  # end
  # ```
  #
  # * `#to_db` converts a property's value into the value bound to the query.
  # It must return something the driver can bind (`DB::Any`), otherwise the query raises.
  # * `#to_crystal_value(value : DB::ResultSet, platform)` reads the next column from the result set while an entity is hydrated.
  # * `#to_crystal_value(value, platform)` converts a value that has already been read, such as a database-generated identifier.
  # * `#sql_declaration` returns the SQL type used to declare a column of this type.
  #
  # WARNING: A type that defines the `to_crystal_value(value : _, platform)` overload must also define the `DB::ResultSet` overload.
  # Otherwise the `value : _` overload would also receive the result set itself, since a subclass's overload takes precedence over the more specific one defined on this type.
  #
  # The ORM makes a few assumptions about the values a type produces:
  #
  # * Changes are detected by comparing a field's value with `==` to the value it was loaded with.
  # Value objects should therefore be immutable and compare by value, as a `record` does.
  # Modifying a mutable object in place isn't detected; assign a new instance instead.
  # * `#to_db` is only called for values being written or compared: the fields an `INSERT` writes, the changed fields an `UPDATE` writes, and identifiers and criteria values in `WHERE` clauses.
  # * Entities are kept in the identity map under the string form of their identifier, so a value object used as an identifier needs a `#to_s` that differs for distinct values.
  #
  # TODO: Value-object identifiers aren't accepted everywhere yet.
  # `AORM::EntityManager#find` ids, repository criteria and `AORM::NativeQuery#set_parameter` take driver-bindable values (`DB::Any`) rather than value objects.
  abstract struct Type
    # Crystal types are mapped to ORM types in `src/mapping/class.cr`
    private BUILTIN_TYPES_MAP = {
      Types::STRING     => AORM::Types::String,
      Types::TEXT       => AORM::Types::String,
      Types::INTEGER    => AORM::Types::Integer,
      Types::SMALLINT   => AORM::Types::SmallInt,
      Types::BIGINT     => AORM::Types::BigInt,
      Types::FLOAT      => AORM::Types::Float,
      Types::SMALLFLOAT => AORM::Types::SmallFloat,
      Types::DECIMAL    => AORM::Types::Decimal,
      Types::BOOLEAN    => AORM::Types::Boolean,
      Types::DATETIME   => AORM::Types::Datetime,
      Types::GUID       => AORM::Types::Guid,
      Types::BINARY     => AORM::Types::Binary,
      Types::BLOB       => AORM::Types::Blob,
    }

    # Returns the registry holding an instance of every known type, keyed by name.
    # It starts out with the built-in types.
    class_getter type_registry : Athena::ORM::Types::TypeRegistry do
      registry = AORM::Types::TypeRegistry.new(BUILTIN_TYPES_MAP.transform_values(&.new.as(AORM::Types::Type)))

      {% if @top_level.has_constant?("BigDecimal") %}
        registry.register Types::NUMBER, AORM::Types::Number.new
      {% end %}

      registry
    end

    # Returns the type registered as *name*.
    #
    # Raises if no type is registered with that name.
    def self.get_type(name : ::String) : self
      self.type_registry.get(name)
    end

    # Registers *type* as *name*, so fields can be mapped to it with `@[AORMA::Column(type: name)]`.
    #
    # Raises if a type is already registered with that name; use `.override_type` to replace one.
    def self.add_type(name : ::String, type : AORM::Types::Type) : Nil
      self.type_registry.register(name, type)
    end

    # Returns `true` if a type is registered as *name*.
    def self.has_type?(name : ::String) : Bool
      self.type_registry.has?(name)
    end

    # Replaces the type registered as *name* with *type*, e.g. to change how a built-in type converts its values.
    #
    # Raises if no type is registered with that name.
    def self.override_type(name : ::String, type : AORM::Types::Type) : Nil
      self.type_registry.override name, type
    end

    # Returns the name of every registered type, mapped to its `Type` struct.
    def self.type_map : Hash(::String, AORM::Types::Type.class)
      self.type_registry.instances.transform_values(&.class)
    end

    # Returns the SQL expression that converts *sql_expression*, a selected column, from its database representation.
    # Returns it unchanged by default.
    #
    # Applied to the columns of a `SELECT`.
    def from_db_sql(sql_expression : ::String, platform : AORM::Platforms::Platform) : ::String
      sql_expression
    end

    # Returns the SQL expression that converts *sql_expression*, a bound parameter's placeholder, to its database representation.
    # Returns it unchanged by default.
    #
    # Applied to the placeholders of values written by an `INSERT` or `UPDATE`, and of criteria values.
    def to_db_sql(sql_expression : ::String, platform : AORM::Platforms::Platform) : ::String
      sql_expression
    end

    # Returns the SQL used to declare *column* as this type on *platform*, e.g. `VARCHAR(255)`.
    #
    # Built-in types delegate to the matching declaration method of `AORM::Platforms::Platform`, which custom types can reuse.
    #
    # TODO: Nothing in the ORM generates schema yet, so this isn't called by the ORM itself.
    abstract def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String

    # Converts *value*, as read from the database, into the Crystal value this type represents.
    # Returns `nil` for a `NULL` value, and raises if *value* can't be converted.
    #
    # Used for values that have already been read, such as a database-generated identifier.
    # Each type defines this once, as the place for its translation logic (parsing, narrowing, decoding, etc.).
    # It accepts any input, since drivers disagree on the Crystal type of some columns, and validates it inside the body, e.g. with `case value`.
    abstract def to_crystal_value(value : _, platform : Platforms::Platform)

    # Reads the next column from *value* and converts it into the Crystal value this type represents.
    # Returns `nil` for a `NULL` value.
    #
    # Used while hydrating entities.
    # Advances the cursor by exactly one column.
    def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform)
      # The default implementation does an untyped read and routes through `to_crystal_value(value, platform)`.
      # A subclass whose `to_crystal_value` takes `value : _` must define this overload as well, since that one would otherwise also receive the result set.
      # It can skip the union-type dispatch when a concrete `rs.read T` is available — for example `Integer` reads `rs.read Int32?` directly.
      self.to_crystal_value value.read, platform
    end

    # Converts *value*, a property's Crystal value, into the value bound to the query.
    # Returns *value* unchanged by default.
    #
    # The returned value must be one the database driver can bind (`DB::Any`), otherwise executing the query raises.
    def to_db(value : _, platform : AORM::Platforms::Platform)
      value
    end

    # :nodoc:
    #
    # Reads the next column with this type, boxing values that are neither driver scalars nor ORM references.
    # Called on each concrete type, so its own `#to_crystal_value` return type is what gets boxed.
    def read_value(rs : DB::ResultSet, platform : Platforms::Platform) : Mapping::ValueAny
      Mapping.box self.to_crystal_value(rs, platform)
    end
  end
end
