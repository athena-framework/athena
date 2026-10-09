# Creates entity managers on a database's connection pool, sharing their class metadata.
#
# An entity manager tracks one unit of work, such as a request or a job, and isn't safe to share between fibers.
# Create the factory once and an entity manager per unit of work:
#
# ```
# ORM = AORM::EntityManagerFactory.new DB.open(ENV["DATABASE_URL"])
#
# ORM.with_entity_manager do |em|
#   em.find!(User, id).name = "George"
#   em.flush
# end
# ```
#
# The factory builds each entity's class metadata once, and shares it with every entity manager it creates.
class Athena::ORM::EntityManagerFactory
  # Returns the database whose connection pool entity managers are created on.
  getter database : DB::Database

  @metadata_cache = Mapping::MetadataCache.new

  # Creates a factory for entity managers on *database*.
  #
  # Every entity manager it creates dispatches its flush and clear events to *event_dispatcher*, see `AORM::EntityManager.new`.
  def initialize(
    @database : DB::Database,
    @event_dispatcher : ACTR::EventDispatcher::Interface? = nil,
  ); end

  # Yields an entity manager on a connection checked out from the pool, and returns the block's value.
  # Afterwards the entity manager is closed, any transaction the block left open is rolled back, and the connection goes back to the pool.
  def with_entity_manager(& : AORM::EntityManager -> T) : T forall T
    @database.using_connection do |connection|
      em = AORM::EntityManager.new connection, @event_dispatcher, metadata_cache: @metadata_cache

      begin
        yield em
      ensure
        em.close

        while em.connection.transaction_active?
          em.rollback
        end
      end
    end
  end
end
