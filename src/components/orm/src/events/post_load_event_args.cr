# Intended to be emitted after an entity has been loaded from the database, or refreshed.
#
# TODO: This event isn't emitted yet, and applying `AORMA::PostLoad` to a method is a compile-time error.
class Athena::ORM::Events::PostLoadEventArgs(T) < Athena::ORM::Events::LifecycleEventArgs(T); end
