# Base type of the events emitted for a single entity, passed to its lifecycle callbacks.
#
# *T* is the entity's class, so `#entity` is typed as that entity.
class Athena::ORM::Events::LifecycleEventArgs(T) < Athena::ORM::Events::EventArgs
  # Returns the entity this event is about.
  getter entity : T

  # Returns the entity manager that emitted this event.
  getter entity_manager : AORM::EntityManagerInterface

  def initialize(
    @entity : T,
    @entity_manager : AORM::EntityManagerInterface,
  ); end
end
