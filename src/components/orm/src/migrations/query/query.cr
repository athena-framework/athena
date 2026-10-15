# A SQL statement a migration executes, with the parameters bound to it, see `AORM::Migrations::AbstractMigration#add_sql`.
struct Athena::ORM::Migrations::Query
  # Returns the SQL of the statement.
  getter statement : String

  # Returns the parameters bound to the statement.
  getter parameters : Array(DB::Any)

  # Returns the name of the `AORM::Types::Type` each parameter is converted through, by position.
  # A parameter without a type is bound as is.
  getter types : Array(String?)

  # Raises `AORM::Migrations::Exception::InvalidArguments` if there are more *types* than *parameters*.
  def initialize(
    @statement : String,
    @parameters : Array(DB::Any) = [] of DB::Any,
    @types : Array(String?) = [] of String?,
  )
    if @types.size > @parameters.size
      raise AORM::Migrations::Exception::InvalidArguments.wrong_types_argument_count @statement, @parameters.size, @types.size
    end
  end

  def to_s(io : IO) : Nil
    io << @statement
  end
end
