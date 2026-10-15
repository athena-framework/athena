# The migrations planned to be executed, in the order they will be, all in the same direction.
class Athena::ORM::Migrations::Metadata::MigrationPlanList
  # Returns the planned migrations.
  getter items : Array(AORM::Migrations::Metadata::MigrationPlan)

  # Returns whether the migrations are to be applied or reverted.
  getter direction : AORM::Migrations::Version::Direction

  def initialize(
    @items : Array(AORM::Migrations::Metadata::MigrationPlan),
    @direction : AORM::Migrations::Version::Direction,
  ); end

  # Returns the number of planned migrations.
  def size : Int32
    @items.size
  end

  # Returns the first planned migration.
  #
  # Raises `AORM::Migrations::Exception::NoMigrationsFoundWithCriteria` if there are none.
  def first : AORM::Migrations::Metadata::MigrationPlan
    @items.first? || raise AORM::Migrations::Exception::NoMigrationsFoundWithCriteria.new "first"
  end

  # Returns the last planned migration.
  #
  # Raises `AORM::Migrations::Exception::NoMigrationsFoundWithCriteria` if there are none.
  def last : AORM::Migrations::Metadata::MigrationPlan
    @items.last? || raise AORM::Migrations::Exception::NoMigrationsFoundWithCriteria.new "last"
  end
end
