# The interface of an entity manager, the central access point to the ORM.
#
# See `AORM::EntityManager` for the default implementation.
module Athena::ORM::EntityManagerInterface
  # The full docs of `#find` and `#find!` are on `AORM::EntityManager`, since `:inherit:` can't match a restriction with a generic type inside a union.

  # Returns the entity of type *entity_class* with the identifier *id*, or `nil` if there isn't one.
  abstract def find(
    entity_class : T.class,
    id : Hash(String, Int | String) | Int | String,
    lock_mode : AORM::LockMode = :none,
    lock_version : Int32? = nil,
  ) : AORM::Entity? forall T

  # Returns the entity of type *entity_class* with the identifier *id*, raising if there isn't one.
  abstract def find!(
    entity_class : T.class,
    id : Hash(String, Int | String) | Int | String,
    lock_mode : AORM::LockMode = :none,
    lock_version : Int32? = nil,
  ) : AORM::Entity forall T

  # Makes the new *entity* managed, so that it's inserted on the next `#flush`.
  #
  # ```
  # user = User.new
  # user.name = "George"
  #
  # em.persist user
  # em.flush # => INSERT INTO users (name) VALUES (?)
  # ```
  #
  # Depending on *entity*'s state:
  #
  # * **New** - It becomes managed, and its `AORMA::PrePersist` callbacks run.
  # * **Managed** - Nothing changes, but associated entities are still persisted if the association cascades `"persist"`.
  # * **Removed** - It's managed again, and won't be deleted.
  #
  # The operation is also applied to the associated entities of associations that cascade `"persist"`, see the [associations](/ORM/#cascading-operations) section of the manual.
  #
  # Database generated identifiers are assigned when the entity is inserted, so they aren't available until the flush.
  #
  # WARNING: Don't pass detached entities.
  # Any entity that isn't known to the entity manager is treated as new, so persisting a detached entity tries to insert it again.
  abstract def persist(entity : AORM::Entity) : Nil

  # Schedules the managed *entity* to be deleted on the next `#flush`.
  #
  # ```
  # user = em.find! User, 1
  #
  # em.remove user
  # em.flush # => DELETE FROM users WHERE id = ?
  # ```
  #
  # Depending on *entity*'s state:
  #
  # * **New** or **Removed** - Nothing changes, but associated entities are still removed if the association cascades `"remove"`.
  # * **Managed** - It becomes removed, and its `AORMA::PreRemove` callbacks run.
  # * **Detached** - Raises an exception.
  #
  # The operation is also applied to the associated entities of associations that cascade `"remove"`, see the [associations](/ORM/#cascading-operations) section of the manual.
  #
  # Until it's flushed, a removed entity can still be found by queries and stays in the collections that contain it.
  # Once it's deleted, a database generated identifier is set back to `nil`, while the rest of its state stays as it was.
  abstract def remove(entity : AORM::Entity) : Nil

  # Detaches every entity this entity manager manages, discarding any changes that weren't flushed.
  # Afterwards, entities are loaded from the database again rather than from the identity map.
  abstract def clear : Nil

  # Reloads the managed *entity*'s columns from the database, discarding any changes that haven't been flushed.
  # Raises an exception if *entity* isn't managed.
  #
  # ```
  # user = em.find! User, 1
  # user.name = "Not saved"
  #
  # em.refresh user
  # user.name # => "George"
  # ```
  #
  # TODO: Associations aren't refreshed, even if the association cascades `"refresh"`.
  # Row locking isn't supported yet either, see `AORM::LockMode`.
  abstract def refresh(entity : AORM::Entity, lock_mode : AORM::LockMode = :none) : Nil

  # Writes all of the changes to the entities this entity manager manages to the database, in a single transaction.
  #
  # This inserts persisted entities, updates changed managed entities, deletes removed entities, and writes the changes to their associations.
  # Changes are only detected on the owning side of an association, see the [associations](/ORM/#associations) section of the manual.
  #
  # Raises an exception if a new entity is found through an association that doesn't cascade `"persist"`.
  # If the flush fails, its transaction is rolled back and the entity manager is closed.
  abstract def flush : Nil

  # Returns the repository of *entity_class*.
  #
  # ```
  # em.repository(User).find_by name: "George" # => [#<User:0x7f3a1c2b5e40 @id=1, @name="George">]
  # ```
  #
  # The repository is an `AORM::EntityRepository` of the entity, or the entity's custom repository class if it has one, see [Custom Repositories][Athena::ORM::EntityRepository--custom-repositories].
  abstract def repository(entity_class : AORM::Entity.class) : AORM::RepositoryInterface

  # Returns `true` if *entity* is managed by this entity manager, i.e. it was loaded or persisted by it, and isn't removed.
  abstract def contains(entity : AORM::Entity) : Bool
  # abstract def get_reference(entity_class : AORM::Entity.class, id : _) : AORM::Entity?

  # abstract def lock : Nil
  # abstract def filters : FilterCollection
  # abstract def filter_state_clean? : Bool
  # abstract def has_filters? : Bool

  # Returns the connection this entity manager executes its queries on.
  abstract def connection : AORM::Connection

  # Starts a transaction, or a savepoint if one is already active.
  # It must be ended with `#commit` or `#rollback`.
  #
  # ```
  # em.begin_transaction
  #
  # begin
  #   # ...
  #
  #   em.flush
  #   em.commit
  # rescue ex
  #   em.rollback
  #   em.close
  #
  #   raise ex
  # end
  # ```
  #
  # TIP: `AORM::EntityManager#wrap_in_transaction` takes care of flushing, committing, and handling errors.
  abstract def begin_transaction : Nil

  # Commits the innermost transaction, or releases its savepoint if it's nested.
  #
  # The entity manager isn't flushed first; call `#flush` before committing.
  abstract def commit : Nil

  # Rolls back the innermost transaction, or to its savepoint if it's nested.
  #
  # Entities keep the state they had in memory, which may no longer match the database.
  # Close the entity manager via `#close` and discard it along with its entities.
  abstract def rollback : Nil

  # Returns the unit of work tracking this entity manager's entities.
  abstract def unit_of_work # : AORM::UnitOfWork

  # Clears the entity manager and marks it closed.
  #
  # A closed entity manager raises on `#persist`, `#remove`, `#refresh`, and `#flush`.
  abstract def close : Nil

  # Returns `true` if this entity manager was closed via `#close`, or by a failed flush.
  abstract def closed? : Bool
end
