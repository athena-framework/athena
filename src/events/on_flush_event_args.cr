# Emitted by `AORM::EntityManager#flush` once the changes to every managed entity have been computed, before anything is written.
#
# Listeners can inspect what the flush is about to do through the unit of work:
#
# ```
# dispatcher = AED::EventDispatcher.new
#
# dispatcher.listener AORM::Events::OnFlushEventArgs do |event|
#   uow = event.entity_manager.unit_of_work
#
#   uow.scheduled_entity_insertions.each { |entity| Log.info { "Inserting #{entity.class}" } }
#   uow.scheduled_entity_updates.each { |entity| Log.info { "Updating #{entity.class}: #{uow.entity_changeset(entity).keys}" } }
#   uow.scheduled_entity_deletions.each { |entity| Log.info { "Deleting #{entity.class}" } }
# end
#
# em = AORM::EntityManager.new connection, dispatcher
# ```
#
# It's emitted on every flush, even when there is nothing to write.
# In that case the flush ends once the event is dispatched, without writing anything a listener persists or changes.
# Only the event dispatcher receives it; there is no lifecycle callback for it.
#
# Change sets are computed before the event is dispatched.
# A listener that persists an entity also computes its change set via `AORM::UnitOfWork#compute_change_set`, and one that changes a managed entity recomputes it via `AORM::UnitOfWork#recompute_single_entity_change_set`.
class Athena::ORM::Events::OnFlushEventArgs < Athena::ORM::Events::ManagerEventArgs; end
