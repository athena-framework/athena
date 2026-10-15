# Generates the fully qualified name of a new migration, which is versioned by the current UTC time, e.g. `App::Migrations::Version20261014120000`.
class Athena::ORM::Migrations::Generator::ClassNameGenerator
  # The `Time::Format` pattern of the version number.
  VERSION_FORMAT = "%Y%m%d%H%M%S"

  # Returns the fully qualified name of a new migration in *namespace*.
  def generate_class_name(namespace : String) : String
    "#{namespace}::Version#{self.generate_version_number}"
  end

  private def generate_version_number : String
    Time.utc.to_s VERSION_FORMAT
  end
end
