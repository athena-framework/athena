# The parent type of every migration.
#
# A migration applies one change to the database's schema or data in `#up`, and reverts it in `#down`, by adding the SQL to execute via `#add_sql`:
#
# ```
# struct App::Migrations::Version20261014120000 < AORM::Migrations::AbstractMigration
#   def description : String
#     "Add the users' email"
#   end
#
#   def up : Nil
#     self.add_sql "ALTER TABLE users ADD email VARCHAR(255) DEFAULT NULL"
#   end
#
#   def down : Nil
#     self.add_sql "ALTER TABLE users DROP email"
#   end
# end
# ```
#
# A new instance is created each time the migration is executed.
# Its SQL is executed once `#up` or `#down` returns, so `#connection` can be used to read the data the migration needs, but changes made through it aren't part of the migration's SQL.
#
# ## Transactions
#
# Each migration runs in a transaction, see `#transactional?`.
# Some databases, such as MySQL and MariaDB, implicitly commit the transaction when a statement changes the schema, such as `CREATE TABLE`.
# Statements executed before such a statement can't be rolled back if a later one fails, so it's best to return `false` from `#transactional?` in migrations that change the schema on those databases.
abstract struct Athena::ORM::Migrations::AbstractMigration
  # Returns the connection the migration is executed on.
  protected getter connection : AORM::Connection

  # Returns the platform of the database the migration is executed on.
  protected getter platform : AORM::Platforms::Platform

  # Returns the SQL added via `#add_sql`, in the order it was added.
  getter sql : Array(AORM::Migrations::Query::Query) = [] of AORM::Migrations::Query::Query

  @frozen : Bool = false

  def initialize(@connection : AORM::Connection)
    @platform = @connection.database_platform
  end

  # Returns `true` if the migration is executed in a transaction.
  def transactional? : Bool
    true
  end

  # Returns a description of what the migration changes.
  def description : String
    ""
  end

  # Logs *message* as a warning if *condition* is `true`.
  def warn_if(condition : Bool, message : String = "Unknown Reason") : Nil
    return unless condition

    Log.warn &.emit message, migration: self.class.name
  end

  # Fails the migration with *message* if *condition* is `true`.
  #
  # Raises `AORM::Migrations::Exception::AbortMigration`.
  def abort_if(condition : Bool, message : String = "Unknown Reason") : Nil
    raise AORM::Migrations::Exception::AbortMigration.new message if condition
  end

  # Stops the migration without failing it if *condition* is `true`, with *message* as the reason.
  #
  # Raises `AORM::Migrations::Exception::SkipMigration`.
  def skip_if(condition : Bool, message : String = "Unknown Reason") : Nil
    raise AORM::Migrations::Exception::SkipMigration.new message if condition
  end

  # Runs before `#up`.
  def pre_up : Nil
  end

  # Runs after the SQL `#up` added has been executed.
  def post_up : Nil
  end

  # Runs before `#down`.
  def pre_down : Nil
  end

  # Runs after the SQL `#down` added has been executed.
  def post_down : Nil
  end

  # Applies the migration's change, by adding the SQL to execute via `#add_sql`.
  abstract def up : Nil

  # Reverts the change `#up` applies, by adding the SQL to execute via `#add_sql`.
  #
  # Fails the migration by default, see `#abort_if`.
  def down : Nil
    self.abort_if true, %(No down() migration implemented for "#{self.class}")
  end

  # Adds *sql* to the statements the migration executes, binding *params*, each converted through the `AORM::Types::Type` named at the same position in *types*.
  #
  # ```
  # self.add_sql "UPDATE users SET created_at = ? WHERE created_at IS NULL", [Time.utc], [AORM::Types::DATETIME] of String?
  # ```
  #
  # Raises `AORM::Migrations::Exception::FrozenMigration` if the migration's SQL has already been executed.
  protected def add_sql(sql : String, params : Array = [] of DB::Any, types : Array(String?) = [] of String?) : Nil
    raise AORM::Migrations::Exception::FrozenMigration.new if @frozen

    @sql << AORM::Migrations::Query::Query.new sql, Array(DB::Any).new(params.size) { |idx| params[idx] }, types
  end

  # :nodoc:
  #
  # Prevents adding SQL once the migration's SQL is executed.
  def freeze : Nil
    @frozen = true
  end

  # Logs *message* as a notice, such as to report the migration's progress.
  protected def write(message : String) : Nil
    Log.notice &.emit message, migration: self.class.name
  end

  # Fails the migration with *message*, such as in a `#down` that can't revert the change `#up` applies.
  #
  # Raises `AORM::Migrations::Exception::IrreversibleMigration`.
  protected def raise_irreversible_migration_exception(message : String? = nil) : NoReturn
    raise AORM::Migrations::Exception::IrreversibleMigration.new(message || "This migration is irreversible and cannot be reverted.")
  end
end
