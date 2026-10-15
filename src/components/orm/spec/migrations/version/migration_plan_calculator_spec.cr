require "../spec_helper"

private alias V1 = MigrationsSpec::Version1
private alias V2 = MigrationsSpec::Version2
private alias V3 = MigrationsSpec::Version3

struct MigrationPlanCalculatorTest < ASPEC::TestCase
  def test_migrations_are_ordered_by_version : Nil
    self.calculator.migrations.items.map(&.migration_class).should eq [V1, V2, V3]
  end

  def test_plan_for_versions : Nil
    plan = self.calculator.plan_for_versions [migrations_spec_version(V3)], :up

    plan.size.should eq 1
    plan.direction.should eq AORM::Migrations::Version::Direction::UP
    plan.first.direction.should eq AORM::Migrations::Version::Direction::UP
    plan.first.version.should eq migrations_spec_version(V3)
    plan.first.migration_class.should eq V3
  end

  def test_plan_for_multiple_versions_is_sorted_up : Nil
    plan = self.calculator.plan_for_versions [migrations_spec_version(V3), migrations_spec_version(V1)], :up

    plan.items.map(&.migration_class).should eq [V1, V3]
  end

  def test_plan_for_multiple_versions_is_sorted_down : Nil
    plan = self.calculator.plan_for_versions [migrations_spec_version(V1), migrations_spec_version(V3)], :down

    plan.direction.should eq AORM::Migrations::Version::Direction::DOWN
    plan.items.map(&.migration_class).should eq [V3, V1]
  end

  def test_plan_for_a_missing_version_raises : Nil
    expect_raises AORM::Migrations::Exception::MigrationClassNotFound, %(Migration class "D" was not found?) do
      self.calculator.plan_for_versions [AORM::Migrations::Version::Version.new("D")], :up
    end
  end

  def test_plan_for_no_versions : Nil
    plan = self.calculator.plan_for_versions [] of AORM::Migrations::Version::Version, :up

    plan.size.should eq 0
    plan.direction.should eq AORM::Migrations::Version::Direction::UP
  end

  @[DataProvider("none_executed_provider")]
  def test_plan_until_version_when_none_executed(to : AORM::Migrations::AbstractMigration.class, expected : Array(AORM::Migrations::AbstractMigration.class)) : Nil
    plan = self.calculator.plan_until_version migrations_spec_version(to)

    plan.direction.should eq AORM::Migrations::Version::Direction::UP
    plan.items.map(&.migration_class).should eq expected
    plan.items.all?(&.direction.up?).should be_true
  end

  def none_executed_provider : Tuple
    {
      {V1, [V1] of AORM::Migrations::AbstractMigration.class},
      {V2, [V1, V2] of AORM::Migrations::AbstractMigration.class},
      {V3, [V1, V2, V3] of AORM::Migrations::AbstractMigration.class},
    }
  end

  @[DataProvider("some_executed_provider")]
  def test_plan_until_version_when_some_executed(to : String, expected : Array(AORM::Migrations::AbstractMigration.class), direction : AORM::Migrations::Version::Direction) : Nil
    plan = self.calculator(InMemoryMetadataStorage.new V1, V2).plan_until_version AORM::Migrations::Version::Version.new(to)

    plan.direction.should eq direction
    plan.items.map(&.migration_class).should eq expected
    plan.items.all?(&.direction.==(direction)).should be_true
  end

  def some_executed_provider : Tuple
    {
      {"0", [V2, V1] of AORM::Migrations::AbstractMigration.class, AORM::Migrations::Version::Direction::DOWN},
      {V1.name, [V2] of AORM::Migrations::AbstractMigration.class, AORM::Migrations::Version::Direction::DOWN},
      {V2.name, [] of AORM::Migrations::AbstractMigration.class, AORM::Migrations::Version::Direction::UP},
      {V3.name, [V3] of AORM::Migrations::AbstractMigration.class, AORM::Migrations::Version::Direction::UP},
    }
  end

  def test_plan_until_version_applies_a_skipped_earlier_migration : Nil
    plan = self.calculator(InMemoryMetadataStorage.new V2, V3).plan_until_version migrations_spec_version(V3)

    plan.direction.should eq AORM::Migrations::Version::Direction::UP
    plan.items.map(&.migration_class).should eq [V1]
  end

  def test_plan_until_a_missing_version_raises : Nil
    expect_raises AORM::Migrations::Exception::MigrationClassNotFound, %(Migration class "D" was not found?) do
      self.calculator.plan_until_version AORM::Migrations::Version::Version.new("D")
    end
  end

  private def calculator(storage : InMemoryMetadataStorage = InMemoryMetadataStorage.new) : AORM::Migrations::Version::MigrationPlanCalculator
    AORM::Migrations::Version::MigrationPlanCalculator.new(
      AORM::Migrations::MigrationsRepository.new([V2, V1, V3] of AORM::Migrations::AbstractMigration.class),
      storage,
    )
  end
end
