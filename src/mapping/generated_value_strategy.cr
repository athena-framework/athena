# How the values of an entity's identifier are generated, as set by `AORMA::GeneratedValue`.
#
# An identifier without an `AORMA::GeneratedValue` annotation uses `NONE`.
enum Athena::ORM::Mapping::GeneratedValueStrategy
  # Picks the strategy preferred by the database platform, which is currently `IDENTITY` on every platform.
  #
  # This is the default when `AORMA::GeneratedValue` is applied without a strategy.
  AUTO

  # Generates values from a database sequence.
  #
  # TODO: Not supported yet; building the metadata of an entity using it raises.
  SEQUENCE

  # The database generates the value when the row is inserted, e.g. via an auto increment or identity column.
  #
  # On platforms supporting `RETURNING` (PostgreSQL, SQLite, MariaDB), the generated values are read back from the `INSERT` statement itself, which also allows composite identifiers whose columns are all generated.
  # Otherwise (MySQL) the value is read back via the last insert ID, which only supports a single identifier column.
  # Either way, the identifier is available on the entity once `AORM::EntityManager#flush` has inserted it.
  IDENTITY

  # The identifier values are assigned by your code, and must be set before the entity is passed to `AORM::EntityManager#persist`.
  NONE

  # Generates values via a custom generator.
  #
  # TODO: Not supported yet; building the metadata of an entity using it raises.
  CUSTOM
end
