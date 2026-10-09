# Base type of every event the ORM emits.
#
# Events reach code in two ways:
#
# * Lifecycle callbacks: methods on an entity annotated with `AORMA::PrePersist`, `AORMA::PostPersist`, `AORMA::PreUpdate`, `AORMA::PostUpdate`, `AORMA::PreRemove`, `AORMA::PostRemove` or `AORMA::PreFlush`.
#   They are invoked for instances of that entity only, and may accept the event as their only argument.
# * The event dispatcher passed to `AORM::EntityManager.new` or `AORM::EntityManagerFactory.new`.
#   It receives the events concerning the entity manager as a whole: `AORM::Events::PreFlushEventArgs`, `AORM::Events::OnFlushEventArgs`, `AORM::Events::PostFlushEventArgs` and `AORM::Events::OnClearEventArgs`.
#
# ```
# @[AORMA::Entity]
# class Article < AORM::Entity
#   @[AORMA::Column]
#   @[AORMA::ID]
#   @[AORMA::GeneratedValue]
#   property! id : Int64
#
#   @[AORMA::Column]
#   property! updated_at : Time
#
#   # Callbacks may omit the event argument.
#   @[AORMA::PrePersist]
#   @[AORMA::PreUpdate]
#   def touch : Nil
#     @updated_at = Time.utc
#   end
#
#   # Or accept it, typed as the event for this entity.
#   @[AORMA::PostPersist]
#   def log_insert(event : AORM::Events::PostPersistEventArgs(Article)) : Nil
#     Log.info { "Inserted article #{event.entity.id}" }
#   end
# end
# ```
#
# Lifecycle callbacks may also be declared in a module, and apply to every entity that includes it.
# More than one callback may be registered for the same event.
#
# WARNING: Calling `AORM::EntityManager#flush` from within an event that is emitted by a flush re-enters the unit of work while it is committing, which isn't supported.
#
# TODO: Per-entity events aren't sent to the event dispatcher yet, and entity listener classes aren't supported; use lifecycle callbacks instead.
abstract class Athena::ORM::Events::EventArgs < ACTR::EventDispatcher::Event
  # TODO: Really worth caching an empty instance?

  # The lifecycle events of an entity are generic instances, which the compiler would otherwise create one at a time while typing the program.
  # Each new one re-types every call already typed through this class or `ACTR::EventDispatcher::Event`, including methods whose body depends on the receiver class, such as `Class#to_s`, for every existing event class, which made compile time grow quadratically with the number of entities.
  # Declaring the lifecycle event types of every entity before any code is typed avoids that.
  macro finished
    {% for entity, idx in Athena::ORM::Entity.all_subclasses.reject { |t| t.abstract? || t <= Athena::ORM::Proxy } %}
      @@pre_persist_{{idx}} : AORM::Events::PrePersistEventArgs({{entity.id}})? = nil
      @@post_persist_{{idx}} : AORM::Events::PostPersistEventArgs({{entity.id}})? = nil
      @@pre_update_{{idx}} : AORM::Events::PreUpdateEventArgs({{entity.id}})? = nil
      @@post_update_{{idx}} : AORM::Events::PostUpdateEventArgs({{entity.id}})? = nil
      @@pre_remove_{{idx}} : AORM::Events::PreRemoveEventArgs({{entity.id}})? = nil
      @@post_remove_{{idx}} : AORM::Events::PostRemoveEventArgs({{entity.id}})? = nil
    {% end %}
  end
end
