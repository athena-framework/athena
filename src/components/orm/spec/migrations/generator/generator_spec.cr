require "file_utils"
require "../spec_helper"

struct GeneratorTest < ASPEC::TestCase
  @directory : String

  def initialize
    @directory = File.tempname "athena_orm_migrations"
  end

  def tear_down : Nil
    FileUtils.rm_rf @directory
  end

  def test_generate_migration : Nil
    path = self.generator.generate_migration "Test::Version1234", %(self.add_sql "SELECT 1"), %(self.add_sql "SELECT 2")

    path.should eq Path[@directory, "version1234.cr"].to_s
    File.read(path).should eq <<-CR
      class Test::Version1234 < AORM::Migrations::AbstractMigration
        def description : String
          ""
        end

        def up : Nil
          # this up migration is auto-generated, please modify it to your needs
          self.add_sql "SELECT 1"
        end

        def down : Nil
          # this down migration is auto-generated, please modify it to your needs
          self.add_sql "SELECT 2"
        end
      end

      CR
  end

  def test_generate_blank_migration : Nil
    File.read(self.generator.generate_migration "Test::Version1234").should eq <<-CR
      class Test::Version1234 < AORM::Migrations::AbstractMigration
        def description : String
          ""
        end

        def up : Nil
          # this up migration is auto-generated, please modify it to your needs
        end

        def down : Nil
          # this down migration is auto-generated, please modify it to your needs
        end
      end

      CR
  end

  def test_multi_line_bodies_are_indented : Nil
    code = File.read self.generator.generate_migration("Test::Version1234", %(self.add_sql "SELECT 1"\nself.add_sql "SELECT 2"))

    code.should contain %(    self.add_sql "SELECT 1"\n    self.add_sql "SELECT 2"\n  end)
  end

  def test_non_transactional_migration : Nil
    code = File.read self.generator(transactional: false).generate_migration("Test::Version1234")

    code.should contain <<-CR
        end

        def transactional? : Bool
          false
        end
      end
      CR
  end

  def test_namespace_without_a_directory_raises : Nil
    expect_raises ArgumentError, %(Path not defined for the namespace "Bar") do
      self.generator.generate_migration "Bar::Version1234"
    end
  end

  def test_invalid_fqcn_raises : Nil
    expect_raises ArgumentError, "Invalid FQCN" do
      self.generator.generate_migration "Version1234"
    end
  end

  @[Tags("compiled")]
  def test_generated_migrations_compile : Nil
    transactional = File.read self.generator.generate_migration("Test::VersionTransactional1234", %(self.add_sql "SELECT 1"))
    non_transactional = File.read self.generator(transactional: false).generate_migration("Test::VersionNonTransactional1234")

    ASPEC::Methods.assert_executes <<-CR
      require "../../../src/migrations"

      #{transactional}
      #{non_transactional}

      # Migrations are only created by the executor, so they're allocated here without a connection.
      raise "Expected the migration to be transactional" unless Test::VersionTransactional1234.allocate.transactional?
      raise "Expected the migration not to be transactional" if Test::VersionNonTransactional1234.allocate.transactional?
      CR
  end

  private def generator(transactional : Bool = true) : AORM::Migrations::Generator
    AORM::Migrations::Generator.new AORM::Migrations::Configuration.new("Test", @directory, transactional)
  end
end
