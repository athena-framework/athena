require "./spec_helper"

struct MigrationsRepositoryTest < ASPEC::TestCase
  @repository : AORM::Migrations::MigrationsRepository

  def initialize
    @repository = AORM::Migrations::MigrationsRepository.new [MigrationsSpec::Version1, MigrationsSpec::Version2] of AORM::Migrations::AbstractMigration.class
  end

  def test_versions_are_the_fully_qualified_type_names : Nil
    @repository.migrations.items.map(&.version.to_s).should eq ["MigrationsSpec::Version1", "MigrationsSpec::Version2"]
  end

  def test_has_migration : Nil
    @repository.has_migration?(version "MigrationsSpec::Version1").should be_true
    @repository.has_migration?(version "MigrationsSpec::Version3").should be_false
  end

  def test_migration : Nil
    @repository.migration(version "MigrationsSpec::Version2").migration_class.should eq MigrationsSpec::Version2
  end

  def test_missing_migration_raises : Nil
    expect_raises AORM::Migrations::Exception::MigrationClassNotFound, %(Migration class "MigrationsSpec::Version3" was not found?) do
      @repository.migration version "MigrationsSpec::Version3"
    end
  end

  def test_duplicate_migration_raises : Nil
    expect_raises AORM::Migrations::Exception::DuplicateMigrationVersion, "Migration version MigrationsSpec::Version1 already registered with class MigrationsSpec::Version1" do
      AORM::Migrations::MigrationsRepository.new [MigrationsSpec::Version1, MigrationsSpec::Version1] of AORM::Migrations::AbstractMigration.class
    end
  end

  private def version(version : String) : AORM::Migrations::Version
    AORM::Migrations::Version.new version
  end
end
