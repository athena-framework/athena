require "file_utils"
require "./spec_helper"

struct GenerateCommandTest < ASPEC::TestCase
  @directory : String

  def initialize
    @directory = File.tempname "athena_orm_migrations"
  end

  def tear_down : Nil
    FileUtils.rm_rf @directory
  end

  def test_generates_a_migration : Nil
    configuration = AORM::Migrations::Configuration.new "App::Migrations", @directory
    tester = ACON::Spec::CommandTester.new AORM::Migrations::Commands::Generate.new(
      configuration,
      AORM::Migrations::Generator.new(configuration),
      AORM::Migrations::Generator::ClassNameGenerator.new,
    )

    tester.execute.should eq ACON::Command::Status::SUCCESS

    files = Dir.children @directory
    files.size.should eq 1
    files.first.should match /^version\d{14}\.cr$/

    fqcn = "App::Migrations::#{files.first.rchop(".cr").camelcase}"
    tester.display.should contain %(Generated new migration class to "#{Path[@directory, files.first]}")
    tester.display.should contain "orm:migrations:execute --up '#{fqcn}'"
    tester.display.should contain "orm:migrations:execute --down '#{fqcn}'"
  end
end

struct SyncMetadataStorageCommandTest < ASPEC::TestCase
  def test_creates_the_table : Nil
    wrapped = MockConnection.new
    wrapped.queue_result [] of Hash(String, DB::Any)
    storage = AORM::Migrations::Metadata::Storage::TableMetadataStorage.new AORM::Connection.new(wrapped)
    tester = ACON::Spec::CommandTester.new AORM::Migrations::Commands::SyncMetadataStorage.new(storage)

    tester.execute.should eq ACON::Command::Status::SUCCESS

    tester.display.should contain "[OK] Metadata storage synchronized"
    wrapped.executed_statements.last[0].should start_with "CREATE TABLE athena_orm_migration_versions"
  end
end
