require "./driver_manager"

module Athena::ORM
  # Wraps a `DB::Connection`, adding the database's `AORM::Platforms::Platform`, parameter conversion through `AORM::Types::Type`s, and nested transactions.
  #
  # Each `AORM::EntityManager` wraps the connection it's created with, available as `AORM::EntityManager#connection`.
  # It can be used to run SQL in the same connection, and transaction, as the entity manager.
  #
  # ```
  # connection = em.connection
  #
  # # Each parameter is converted through the type at the same position before being bound.
  # connection.execute_statement "UPDATE posts SET published_at = ? WHERE id = ?", [Time.utc, 1], [AORM::Types::DATETIME, AORM::Types::INTEGER] of String? # => 1
  #
  # connection.fetch_one "SELECT COUNT(*) FROM posts", [] of DB::Any, [] of String? # => 10
  # ```
  #
  # The `DB::QueryMethods` methods, such as `#exec` and `#query`, bind their arguments as given, without any conversion.
  # Other methods are forwarded to the wrapped connection.
  #
  # ## Transactions
  #
  # `#begin_transaction` starts a transaction, or a savepoint within the active one when a transaction is already active.
  # `#commit` and `#rollback` end the innermost one, so a nested transaction can be rolled back without affecting the outer transaction.
  #
  # ```
  # connection.transactional do
  #   connection.exec "DELETE FROM posts WHERE user_id = ?", 1
  #   connection.exec "DELETE FROM users WHERE id = ?", 1
  # end
  # ```
  #
  # Since `AORM::EntityManager#flush` runs in a transaction of its own, it becomes a savepoint when called within one.
  #
  # TIP: `AORM::EntityManager#wrap_in_transaction` also flushes the entity manager before committing, and closes it if anything raises.
  class Connection
    include DB::QueryMethods(DB::Statement)

    # Returns the platform of the database this connection is to.
    getter platform : Platforms::Platform

    # Returns the wrapped driver connection.
    getter wrapped : DB::Connection

    # Returns the driver of the wrapped connection's driver shard.
    getter driver : AORM::Driver

    # Open transactions, outermost first.
    # Nested ones are savepoints within the outer transaction.
    @transactions = [] of DB::Transaction

    # The identifier the driver shard reported for the last statement executed via `#exec`, `0` if it didn't generate one.
    @reported_insert_id : Int64 = 0_i64

    # Wraps *wrapped*, using *driver* for what differs between driver shards, such as the platform of the database it's to.
    #
    # Raises `AORM::Exceptions::UnknownDriver` if no *driver* is given and the ORM doesn't support *wrapped*'s driver shard, see `AORM::DriverManager`.
    def initialize(@wrapped : DB::Connection, @driver : AORM::Driver = AORM::DriverManager.driver(wrapped))
      @platform = @driver.database_platform @wrapped
    end

    # Returns the platform of the database this connection is to.
    def database_platform : Platforms::Platform
      @platform
    end

    # :nodoc:
    #
    # Boxed values already hold a type's Crystal-side value, so they pass through unchanged.
    def convert_to_crystal_value(value : _, type : String?)
      return value if value.is_a?(Mapping::Opaque)

      Types::Type.get_type(type.not_nil!).to_crystal_value(value, self.database_platform)
    end

    # Converts *value* to its database representation through the `Types::Type` registered as *type*.
    # Values without a type are returned unchanged.
    def convert_to_database_value(value : _, type : String?)
      return value unless type

      Types::Type.get_type(type).to_db value, self.database_platform
    end

    # Executes *sql*, binding each of *params* converted through the type at the same position in *types*, and returns the number of affected rows.
    def execute_statement(sql : String, params : Array, types : Array(String?)) : Int64
      self.exec(sql, args: self.convert_parameters(params, types)).rows_affected
    end

    # Executes *sql*, binding each of *params* converted through the type at the same position in *types*, and yields the result set.
    # Returns the block's value.
    def execute_query(sql : String, params : Array, types : Array(String?), &)
      self.query sql, args: self.convert_parameters(params, types) do |rs|
        yield rs
      end
    end

    # Executes *sql*, binding each of *params* converted through the type at the same position in *types*, and returns the result set.
    # The caller is responsible for closing it.
    def execute_query(sql : String, params : Array, types : Array(String?)) : DB::ResultSet
      self.query sql, args: self.convert_parameters(params, types)
    end

    # Executes *sql* like `#execute_query`, returning the first column of the first row, or `nil` when there are no rows.
    def fetch_one(sql : String, params : Array, types : Array(String?))
      self.execute_query sql, params, types do |rs|
        rs.move_next ? rs.read : nil
      end
    end

    # The driver picks each parameter's encoding from its runtime class, so only the value is converted; there is no separate binding type.
    # Parameters may be wrapped in a `Mapping::Value`, and converting is what narrows them to something the driver can bind.
    private def convert_parameters(params : Array, types : Array(String?)) : Array(DB::Any)
      Array(DB::Any).new(params.size) do |idx|
        param = params[idx]
        value = param.is_a?(Mapping::Value) ? param.value : param
        converted = if value.is_a?(Mapping::Opaque)
                      value.to_db types[idx]?.try { |type| Types::Type.get_type type }, self.database_platform
                    else
                      self.convert_to_database_value value, types[idx]?
                    end

        unless converted.is_a?(DB::Any)
          raise "Cannot bind parameter #{idx + 1}: #{types[idx]? ? "type '#{types[idx]?}'" : "no type"} converted #{value.class} to #{converted.class}, which the driver cannot bind."
        end

        converted
      end
    end

    # :inherit:
    #
    # Also keeps the identifier the statement generated, see `#last_insert_id`.
    def exec(query, *args_, args : Enumerable? = nil) : DB::ExecResult
      result = super
      @reported_insert_id = result.last_insert_id
      result
    end

    # Returns the identifier generated by the last statement executed via `#exec`.
    #
    # Raises `AORM::Exceptions::NoIdentityValue` if that statement didn't generate one.
    # On Postgres, it's instead the value most recently generated by a sequence in this session, and the driver shard raises if no sequence was used yet.
    def last_insert_id : Int64
      @driver.last_insert_id @wrapped, @reported_insert_id
    end

    # :nodoc:
    #
    # Required by DB::QueryMethods - prepares the provided SQL and returns a build statement after any required processing.
    def build(query) : DB::Statement
      @driver.prepare @wrapped, query
    end

    # Starts a transaction, or a savepoint if one is already active.
    def begin_transaction : Nil
      @transactions << (@transactions.last?.try(&.begin_transaction) || @wrapped.begin_transaction)
    end

    # Commits the innermost transaction, releasing its savepoint if it's nested.
    #
    # Raises `DB::Error` if no transaction is active.
    # A commit that fails still ends the transaction.
    def commit : Nil
      transaction = @transactions.pop? || raise DB::Error.new "There is no active transaction."

      begin
        transaction.commit
      ensure
        # Resets the driver's transaction state if the commit failed; a failed commit still ends the transaction.
        transaction.close
      end
    end

    # Rolls back the innermost transaction, or to its savepoint if it's nested.
    #
    # Raises `DB::Error` if no transaction is active.
    def rollback : Nil
      transaction = @transactions.pop? || raise DB::Error.new "There is no active transaction."

      begin
        transaction.rollback
      ensure
        transaction.close
      end
    end

    # Returns `true` if a transaction is active.
    def transaction_active? : Bool
      !@transactions.empty?
    end

    # Returns the number of active transactions, counting each savepoint as one.
    def transaction_nesting_level : Int32
      @transactions.size
    end

    # Runs the block in a transaction, or a savepoint if one is already active.
    # Commits if the block returns, returning its value, and rolls back if it raises.
    def transactional(& : self -> T) : T forall T
      self.begin_transaction

      begin
        result = yield self
      rescue ex
        self.rollback
        raise ex
      end

      self.commit

      result
    end

    forward_missing_to @wrapped
  end
end
