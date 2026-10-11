# Provides the `AORM::EntityManager` of the current unit of work, such as a request.
#
# The entity manager is created the first time it's needed, on a connection checked out from the connection pool of the configured [url](/ORM/Bundle/Schema/#Athena::ORM::Bundle::Schema#url).
# `#close` closes it and returns its connection to the pool, which the [Athena Framework](/Framework/) does once each request is done.
# `#reset` only clears it, which the framework does between the requests made within a test, see [ADI::Spec::ContainerTestCase](/DependencyInjection/Spec/ContainerTestCase/).
class Athena::ORM::Bundle::Registry
  include ACTR::Service::Closeable
  include ACTR::Service::Resettable

  # The connection pool and class metadata, shared by every unit of work.
  @@database : DB::Database? = nil
  @@metadata_cache = AORM::Mapping::MetadataCache.new

  # Opening the pool connects to the database, so another fiber may run before it's assigned.
  @@database_mutex = Mutex.new

  # :nodoc:
  def self.entity_manager(registry : Athena::ORM::Bundle::Registry) : AORM::EntityManager
    registry.manager
  end

  @entity_manager : AORM::EntityManager? = nil

  def initialize(
    @url : String,
    @event_dispatcher : ACTR::EventDispatcher::Interface? = nil,
  ); end

  # Returns the entity manager of the current unit of work, creating it if needed.
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

  # Clears the entity manager, if one was created, keeping it open on its connection.
  #
  # Transactions left open are left to whoever began them.
  def reset : Nil
    @entity_manager.try &.clear
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
