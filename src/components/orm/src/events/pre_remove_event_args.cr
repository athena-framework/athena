# Emitted when a managed entity is passed to `AORM::EntityManager#remove`, or the removal cascades to it from an association mapped with `cascade: ["remove"]`.
#
# It's emitted immediately, before the entity is scheduled for deletion; the DELETE itself runs on the next flush.
# Lifecycle callbacks annotated with `AORMA::PreRemove` receive it.
class Athena::ORM::Events::PreRemoveEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T); end
