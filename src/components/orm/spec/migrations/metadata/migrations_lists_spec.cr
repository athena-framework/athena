require "../spec_helper"

private def version(version : String) : AORM::Migrations::Version
  AORM::Migrations::Version.new version
end

private def available(name : String) : AORM::Migrations::Metadata::AvailableMigration
  AORM::Migrations::Metadata::AvailableMigration.new version(name), MigrationsSpec::Version1
end

private def executed(name : String) : AORM::Migrations::Metadata::ExecutedMigration
  AORM::Migrations::Metadata::ExecutedMigration.new version(name)
end

struct AvailableMigrationsListTest < ASPEC::TestCase
  @list = AORM::Migrations::Metadata::AvailableMigrationsList.new [available("A"), available("B"), available("C")]

  def test_first : Nil
    @list.first.version.should eq version "A"
    @list.first(1).version.should eq version "B"

    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria, "Could not find any migrations matching your criteria (first+3)." do
      @list.first 3
    end
  end

  def test_last : Nil
    @list.last.version.should eq version "C"
    @list.last(-1).version.should eq version "B"

    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria, "Could not find any migrations matching your criteria (last)." do
      @list.last -3
    end
  end

  def test_last_of_empty_list_raises : Nil
    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria do
      AORM::Migrations::Metadata::AvailableMigrationsList.new([] of AORM::Migrations::Metadata::AvailableMigration).last
    end
  end

  def test_migration : Nil
    @list.size.should eq 3
    @list.has_migration?(version "B").should be_true
    @list.has_migration?(version "D").should be_false
    @list.migration(version "B").version.should eq version "B"

    expect_raises AORM::Migrations::Exception::MigrationNotAvailable, "The migration D is not available" do
      @list.migration version "D"
    end
  end

  def test_new_subset_excludes_executed_migrations : Nil
    subset = @list.new_subset AORM::Migrations::Metadata::ExecutedMigrationsList.new [executed("B"), executed("Z")]

    subset.items.map(&.version.to_s).should eq ["A", "C"]
  end
end

struct AvailableMigrationsSetTest < ASPEC::TestCase
  def test_migration : Nil
    set = AORM::Migrations::Metadata::AvailableMigrationsSet.new [available("A")]

    set.size.should eq 1
    set.has_migration?(version "A").should be_true
    set.has_migration?(version "B").should be_false
    set.migration(version "A").version.should eq version "A"

    expect_raises AORM::Migrations::Exception::MigrationNotAvailable, "The migration B is not available" do
      set.migration version "B"
    end
  end
end

struct ExecutedMigrationsListTest < ASPEC::TestCase
  @list = AORM::Migrations::Metadata::ExecutedMigrationsList.new [executed("A"), executed("B")]

  def test_first_and_last : Nil
    @list.first.version.should eq version "A"
    @list.last.version.should eq version "B"
    @list.last(-1).version.should eq version "A"

    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria, "Could not find any migrations matching your criteria (first+2)." do
      @list.first 2
    end
  end

  def test_migration : Nil
    @list.size.should eq 2
    @list.has_migration?(version "A").should be_true
    @list.migration(version "A").version.should eq version "A"

    expect_raises AORM::Migrations::Exception::MigrationNotExecuted, "The provided migration C has not been executed" do
      @list.migration version "C"
    end
  end

  def test_unavailable_subset_is_the_executed_migrations_that_are_not_available : Nil
    subset = @list.unavailable_subset AORM::Migrations::Metadata::AvailableMigrationsList.new [available("A")]

    subset.items.map(&.version.to_s).should eq ["B"]
  end
end

struct MigrationPlanTest < ASPEC::TestCase
  def test_mark_as_executed_only_once : Nil
    plan = AORM::Migrations::Metadata::MigrationPlan.new version("A"), MigrationsSpec::Version1, :up
    result = AORM::Migrations::Version::ExecutionResult.new version("A")

    plan.result.should be_nil
    plan.mark_as_executed result
    plan.result.should be result

    expect_raises AORM::Migrations::Exception::PlanAlreadyExecuted, "This plan was already marked as executed." do
      plan.mark_as_executed result
    end
  end

  def test_plan_list_first_and_last : Nil
    a = AORM::Migrations::Metadata::MigrationPlan.new version("A"), MigrationsSpec::Version1, :up
    b = AORM::Migrations::Metadata::MigrationPlan.new version("B"), MigrationsSpec::Version2, :up
    list = AORM::Migrations::Metadata::MigrationPlanList.new [a, b], :up

    list.size.should eq 2
    list.direction.should eq AORM::Migrations::Version::Direction::UP
    list.first.should be a
    list.last.should be b
  end

  def test_empty_plan_list_raises : Nil
    list = AORM::Migrations::Metadata::MigrationPlanList.new [] of AORM::Migrations::Metadata::MigrationPlan, :down

    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria, "Could not find any migrations matching your criteria (first)." do
      list.first
    end

    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria, "Could not find any migrations matching your criteria (last)." do
      list.last
    end
  end
end

struct ExecutionResultTest < ASPEC::TestCase
  def test_defaults_and_error : Nil
    result = AORM::Migrations::Version::ExecutionResult.new version("A")

    result.direction.should eq AORM::Migrations::Version::Direction::UP
    result.state.should eq AORM::Migrations::Version::State::NONE
    result.has_sql?.should be_false
    result.error?.should be_false
    result.skipped?.should be_false

    ex = Exception.new "boom"
    result.set_error true, ex
    result.error?.should be_true
    result.exception.should be ex
  end
end
