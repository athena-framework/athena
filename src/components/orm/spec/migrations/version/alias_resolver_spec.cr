require "../spec_helper"

private alias V1 = MigrationsSpec::Version1
private alias V2 = MigrationsSpec::Version2
private alias V3 = MigrationsSpec::Version3

struct AliasResolverTest < ASPEC::TestCase
  @[DataProvider("some_executed_provider")]
  def test_aliases_when_some_executed(version_alias : String, expected : String) : Nil
    self.resolver(InMemoryMetadataStorage.new V1, V2).resolve_version_alias(version_alias).to_s.should eq expected
  end

  def some_executed_provider : Tuple
    {
      {"first", "0"},
      {"0", "0"},
      {"current", V2.name},
      {"prev", V1.name},
      {"next", V3.name},
      {"latest", V3.name},
      {"current-1", V1.name},
      {"current+1", V3.name},
      {V2.name, V2.name},
    }
  end

  @[DataProvider("none_executed_provider")]
  def test_aliases_when_none_executed(version_alias : String, expected : String) : Nil
    self.resolver.resolve_version_alias(version_alias).to_s.should eq expected
  end

  def none_executed_provider : Tuple
    {
      {"first", "0"},
      {"current", "0"},
      {"prev", "0"},
      {"next", V1.name},
      {"latest", V3.name},
      {"current+1", V1.name},
      {V2.name, V2.name},
    }
  end

  def test_unknown_version_raises : Nil
    expect_raises AORM::Migrations::Exception::UnknownMigrationVersion, "Could not find migration version X" do
      self.resolver.resolve_version_alias "X"
    end
  end

  def test_offset_before_the_first_executed_migration_raises : Nil
    expect_raises AORM::Migrations::Exception::NoMigrationsFoundWithCriteria do
      self.resolver.resolve_version_alias "current-1"
    end
  end

  def test_next_raises_when_every_migration_is_executed : Nil
    expect_raises AORM::Migrations::Exception::NoMigrationsToExecute, "Could not find any migrations to execute." do
      self.resolver(InMemoryMetadataStorage.new V1, V2, V3).resolve_version_alias "next"
    end
  end

  def test_latest_falls_back_to_current_without_migrations : Nil
    storage = InMemoryMetadataStorage.new V1
    repository = AORM::Migrations::MigrationsRepository.new [] of AORM::Migrations::AbstractMigration.class

    self.resolver(storage, repository).resolve_version_alias("latest").to_s.should eq V1.name
  end

  private def resolver(
    storage : InMemoryMetadataStorage = InMemoryMetadataStorage.new,
    repository : AORM::Migrations::MigrationsRepository = AORM::Migrations::MigrationsRepository.new([V1, V2, V3] of AORM::Migrations::AbstractMigration.class),
  ) : AORM::Migrations::Version::AliasResolver
    plan_calculator = AORM::Migrations::Version::MigrationPlanCalculator.new repository, storage

    AORM::Migrations::Version::AliasResolver.new(
      plan_calculator,
      storage,
      AORM::Migrations::Version::MigrationStatusCalculator.new(plan_calculator, storage),
    )
  end
end
