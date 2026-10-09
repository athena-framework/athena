# Base type of the events concerning an entity manager as a whole, rather than a single entity.
abstract class Athena::ORM::Events::ManagerEventArgs < Athena::ORM::Events::EventArgs
  # Returns the entity manager that emitted this event.
  getter entity_manager : AORM::EntityManagerInterface

  def initialize(
    @entity_manager : AORM::EntityManagerInterface,
  ); end
end
