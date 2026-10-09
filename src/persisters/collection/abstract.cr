require "./interface"

# :nodoc:
abstract class Athena::ORM::Persisters::Collection::Abstract
  include Athena::ORM::Persisters::Collection::Interface

  @em : AORM::EntityManagerInterface
  @connection : AORM::Connection
  @uow : AORM::UnitOfWork
  @platform : Platforms::Platform
  @quote_strategy : Mapping::QuoteStrategyInterface

  def initialize(@em : AORM::EntityManagerInterface)
    @uow = @em.unit_of_work
    @connection = @em.connection
    @platform = @connection.database_platform
    @quote_strategy = Mapping::DefaultQuoteStrategy.new
  end

  # Checks if an entity is in a valid state for collection operations.
  protected def valid_entity_state?(entity : AORM::Entity) : Bool
    state = @uow.entity_state entity, :new

    return false if state.new?

    # If Entity is scheduled for inclusion, it is not in this collection.
    # We can assure that because it would have return true before on array check
    !(state.managed? && @uow.is_scheduled_for_insert? entity)
  end
end
