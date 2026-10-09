# The kind of inheritance mapping an entity hierarchy uses.
#
# TODO: Inheritance mapping isn't supported yet, so every entity uses `NONE`.
enum Athena::ORM::Mapping::InheritanceType
  # The entity isn't part of a mapped inheritance hierarchy.
  NONE

  # Each class in the hierarchy is stored in its own table, joined to its parent's.
  JOINED

  # The whole hierarchy is stored in one table, with a discriminator column identifying each row's class.
  SINGLE_TABLE
end
