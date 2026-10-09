# Emitted during `AORM::EntityManager#flush` for each entity it updated, right after that entity's UPDATE and before the transaction is committed.
#
# Lifecycle callbacks annotated with `AORMA::PostUpdate` receive it.
#
# Changes made to the entity here aren't written by this flush; use it for side effects such as logging, or for state that isn't mapped.
class Athena::ORM::Events::PostUpdateEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T); end
