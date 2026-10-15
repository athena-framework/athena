# The version of a migration, which is the fully qualified name of its type.
#
# Also contains the types that plan and execute migrations, such as `Version::Executor`.
struct Athena::ORM::Migrations::Version
  def initialize(@version : String); end

  def_equals_and_hash @version

  def to_s(io : IO) : Nil
    io << @version
  end
end
