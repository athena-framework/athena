# How an association is loaded, as set by the `fetch_mode` argument of the association annotations.
#
# TODO: The fetch mode is recorded, but doesn't affect loading yet.
# Collections always load lazily, the first time they're accessed.
# A ToOne association loads eagerly unless its property is typed `AORM::Proxy(T)?`, which makes it load lazily.
enum Athena::ORM::Mapping::FetchMode
  # Loads the association the first time it's accessed.
  LAZY

  # Loads the association together with the entity that holds it.
  EAGER

  # Loads a collection lazily, but allows operations such as `#size` or `#includes?` to query the database without loading the whole collection.
  EXTRA_LAZY
end
