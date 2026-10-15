require "ecr"

# Writes the file of a new migration.
#
# ```
# configuration = AORM::Migrations::Configuration.new "App::Migrations", "src/migrations"
# generator = AORM::Migrations::Generator.new configuration
#
# generator.generate_migration "App::Migrations::Version20261014120000" # => "src/migrations/version20261014120000.cr"
# ```
class Athena::ORM::Migrations::Generator
  # :nodoc:
  #
  # Renders the code of a migration.
  record MigrationTemplate, namespace : String, class_name : String, up : String?, down : String?, transactional : Bool do
    ECR.def_to_s "#{__DIR__}/migration.ecr"

    private def body(code : String?) : String
      # Returns *code* indented as a method body, each line ending in a newline, or nothing if there's no *code*.
      # This isn't a doc comment, which `crystal docs` emits between `private` and `def` when expanding the `record` block, failing to parse it.
      return "" if code.nil?

      code.each_line.join { |line| "    #{line}\n" }
    end
  end

  def initialize(@configuration : AORM::Migrations::Configuration); end

  # Writes the migration named *fqcn* to the configured directory, with *up* and *down* as the bodies of its `#up` and `#down`, and returns the path of the file.
  # The directory is created if it doesn't exist.
  #
  # Raises an `ArgumentError` if *fqcn* isn't in the configured namespace.
  def generate_migration(fqcn : String, up : String? = nil, down : String? = nil) : String
    namespace, separator, class_name = fqcn.rpartition "::"

    raise ArgumentError.new "Invalid FQCN" if separator.empty? || namespace.empty? || class_name.empty?

    unless namespace == @configuration.namespace
      raise ArgumentError.new %(Path not defined for the namespace "#{namespace}")
    end

    Dir.mkdir_p @configuration.directory

    path = Path[@configuration.directory, "#{class_name.underscore}.cr"].to_s

    File.write path, MigrationTemplate.new(namespace, class_name, up, down, @configuration.transactional?).to_s

    path
  end
end
