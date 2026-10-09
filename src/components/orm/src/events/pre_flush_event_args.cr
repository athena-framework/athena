# Emitted at the start of `AORM::EntityManager#flush`, before any changes are computed.
#
# The event dispatcher receives it once per flush.
# Lifecycle callbacks annotated with `AORMA::PreFlush` also receive it, once for each entity the flush checks for changes: new entities about to be inserted, and managed entities that aren't read-only or scheduled for removal.
# Changes those callbacks make to their entity are written by the same flush.
#
# ```
# @[AORMA::Entity]
# class Article < AORM::Entity
#   # ...
#
#   @[AORMA::Column]
#   property title : String = ""
#
#   @[AORMA::PreFlush]
#   def normalize_title(event : AORM::Events::PreFlushEventArgs) : Nil
#     @title = @title.strip
#   end
# end
# ```
#
# WARNING: Calling `AORM::EntityManager#flush` from a listener of this event emits it again, recursing forever.
class Athena::ORM::Events::PreFlushEventArgs < Athena::ORM::Events::ManagerEventArgs; end
