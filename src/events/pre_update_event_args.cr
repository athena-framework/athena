# Emitted during `AORM::EntityManager#flush` for each managed entity with changes, right before its UPDATE.
#
# Lifecycle callbacks annotated with `AORMA::PreUpdate` receive it.
# Changes they make to the entity's fields are written by the same UPDATE.
# Changes to collections aren't.
#
# ```
# @[AORMA::Entity]
# class Article < AORM::Entity
#   # ...
#
#   @[AORMA::PreUpdate]
#   def set_updated_at : Nil
#     @updated_at = Time.utc
#   end
# end
# ```
#
# TODO: The event doesn't expose the entity's change set yet; `AORM::UnitOfWork#entity_changeset` returns it in the meantime.
class Athena::ORM::Events::PreUpdateEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T)
  # TODO: Changeset API
end
