require "./abstract_mysql"

# Base platform for MySQL.
#
# MySQL doesn't support `INSERT ... RETURNING`, so a database-generated identifier is the one the server reports for the `INSERT` (the value of `LAST_INSERT_ID()`), which limits it to a single identifier column.
#
# NOTE: The `mysql` driver shard only supports the `mysql_native_password` authentication plugin.
# The server's `authentication_policy` must default to it, in addition to the account using it, as the `caching_sha2_password` default of MySQL 8.0+ can't be used.
class Athena::ORM::Platforms::MySQL < Athena::ORM::Platforms::AbstractMySQL
end
