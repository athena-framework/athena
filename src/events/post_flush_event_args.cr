# Emitted at the end of `AORM::EntityManager#flush`, after the transaction has been committed.
#
# It's emitted on every successful flush, even when there was nothing to write.
# Only the event dispatcher receives it; there is no lifecycle callback for it.
#
# WARNING: `AORM::EntityManager#flush` can't safely be called from a listener of this event.
class Athena::ORM::Events::PostFlushEventArgs < Athena::ORM::Events::ManagerEventArgs; end
