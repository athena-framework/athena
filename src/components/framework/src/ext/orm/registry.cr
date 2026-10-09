# Provides the [AORM::EntityManager](/ORM/EntityManager/) of the current request.
#
# The entity manager is created the first time it's needed, on a connection checked out from the connection pool of the configured `ATH::Bundle::Schema::ORM#url`.
# Once the request is done, `#close` closes it and returns its connection to the pool.
#
# Inject [AORM::EntityManagerInterface](/ORM/EntityManagerInterface/) to use the entity manager:
#
# ```
# @[ADI::Register]
# class UserController < ATH::Controller
#   def initialize(@em : AORM::EntityManagerInterface); end
#
#   @[ARTA::Get("/user/{id}")]
#   def user(id : Int64) : User?
#     @em.find User, id
#   end
# end
# ```
class Athena::Framework::ORM::Registry
  include ATH::Closeable

  # The connection pool and class metadata, shared by every request.
  @@database : DB::Database? = nil
  @@metadata_cache = AORM::Mapping::MetadataCache.new

  # Opening the pool connects to the database, so another request's fiber may run before it's assigned.
  @@database_mutex = Mutex.new

  # :nodoc:
  def self.entity_manager(registry : ATH::ORM::Registry) : AORM::EntityManager
    registry.manager
  end

  @entity_manager : AORM::EntityManager? = nil

  def initialize(
    @url : String,
    @event_dispatcher : ACTR::EventDispatcher::Interface,
  ); end

  # Returns the entity manager of the current request, creating it if needed.
  def manager : AORM::EntityManager
    @entity_manager ||= begin
      database = @@database_mutex.synchronize { @@database ||= DB.open @url }

      connection = database.checkout

      begin
        AORM::EntityManager.new connection, @event_dispatcher, metadata_cache: @@metadata_cache
      rescue ex
        connection.release
        raise ex
      end
    end
  end

  # Closes the entity manager, if one was created, rolling back any transaction left open and returning its connection to the pool.
  def close : Nil
    return unless entity_manager = @entity_manager

    @entity_manager = nil

    begin
      entity_manager.close

      while entity_manager.connection.transaction_active?
        entity_manager.rollback
      end
    ensure
      entity_manager.connection.wrapped.release
    end
  end
end
