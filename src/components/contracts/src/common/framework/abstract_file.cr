require "file_utils"

require "athena-mime"

# Represents a file on the filesystem without opening a file descriptor.
# This base type is needed as you can't inherit from non-abstract structs,
# and it makes sense to have a generic `Athena::Framework::File` type while also being able to share the logic with other sub-types.
#
# TODO: Add more methods as needed.
abstract struct Athena::Framework::AbstractFile
  getter path : String

  def initialize(path : String | Path, check_path : Bool = true)
    if check_path && !::File.file?(path)
      raise Athena::Framework::Exception::FileNotFound.new "The file does not exist.", file: path
    end

    @path = path.to_s
  end

  def guess_extension : String?
    return unless mime_type = self.mime_type

    AMIME::Types.default.extensions(mime_type).first?
  end

  def mime_type : String?
    AMIME::Types.default.guess_mime_type @path
  end

  def move(directory : Path | String, name : String? = nil) : self
    target = self.target_file directory, name

    FileUtils.mv @path, target.path

    target
  end

  def content : String
    ::File.read @path
  end

  def basename(suffix : String? = nil) : String
    suffix ? ::File.basename(@path, suffix) : ::File.basename(@path)
  end

  def realpath : String
    ::File.realpath @path
  end

  private def target_file(directory : String | Path, name : String? = nil) : Athena::Framework::File
    if !::File.directory? directory
      Dir.mkdir_p directory
    elsif !::File::Info.writable?(directory)
      raise ArgumentError.new "Unable to write in the '#{directory}' directory."
    end

    Athena::Framework::File.new Path[directory, (file_name = name.presence) ? self.clean_name(file_name) : self.basename], false
  end

  private def clean_name(name : String) : String
    original_name = name.gsub "\\", "/"

    Path.new(original_name).basename
  end
end
