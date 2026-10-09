# Emitted during `AORM::EntityManager#flush` for each entity it deleted, once every DELETE has run but before the transaction is committed.
#
# The entity's in-memory state is unchanged, except that a generated identifier is reset to `nil`.
# Lifecycle callbacks annotated with `AORMA::PostRemove` receive it.
class Athena::ORM::Events::PostRemoveEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T); end
