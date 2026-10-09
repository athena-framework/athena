# Emitted by `AORM::EntityManager#clear`, after every entity has been detached from the unit of work.
#
# `AORM::EntityManager#close` clears the entity manager too, so it also emits this event.
# Only the event dispatcher receives it; there is no lifecycle callback for it.
class Athena::ORM::Events::OnClearEventArgs < Athena::ORM::Events::EventArgs
  # Returns the entity manager that was cleared.
  getter entity_manager : AORM::EntityManagerInterface

  def initialize(
    @entity_manager : AORM::EntityManagerInterface,
  ); end
end
