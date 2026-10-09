# Emitted during `AORM::EntityManager#flush` for each entity it inserted, once every INSERT has run but before the transaction is committed.
#
# Generated identifiers are available at this point.
# Lifecycle callbacks annotated with `AORMA::PostPersist` receive it.
#
# Changes made to the entity here aren't written by this flush; use it for side effects such as logging, or for state that isn't mapped.
#
# NOTE: Collection and other follow-up updates for the flush may still be pending, so the database may not fully reflect the in-memory state yet.
class Athena::ORM::Events::PostPersistEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T); end
