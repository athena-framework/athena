require "file_utils"

require "athena-mime"

# Represents a file on the filesystem without opening a file descriptor.
# This base type is needed as you can't inherit from non-abstract structs,
# and it makes sense to have a generic `Athena::Framework::File` type while also being able to share the logic with other sub-types.
#
# TODO: Add more methods as needed.
abstract struct Athena::Framework::AbstractFile
  # Returns the path to this file, which may be relative.
  getter path : String

  # Create a new instance for the file at the provided *path*.
  # If *check_path* is `true`, then an `ATH::Exception::FileNotFound` exception is raised if the file at the provided *path* does not exist.
  def initialize(path : String | Path, check_path : Bool = true)
    if check_path && !::File.file?(path)
      raise Athena::Framework::Exception::FileNotFound.new "The file does not exist.", file: path
    end

    @path = path.to_s
  end

  # Returns the extension based on the MIME type of this file, or `nil` if it is unknown.
  # Uses the MIME type as guessed by `#mime_type` to guess the file extension.
  #
  # ```
  # file = ATH::File.new "/path/to/foo.txt"
  # file.guess_extension # => "txt"
  # ```
  def guess_extension : String?
    return unless mime_type = self.mime_type

    AMIME::Types.default.extensions(mime_type).first?
  end

  # Returns the MIME type of this file, using [AMIME::Types](/MIME/Types) under the hood.
  #
  # ```
  # file = ATH::File.new "/path/to/foo.txt"
  # file.mime_type # => "text/plain"
  # ```
  def mime_type : String?
    AMIME::Types.default.guess_mime_type @path
  end

  # Moves this file to the provided *directory*, optionally with the provided *name*.
  # If no *name* is provided, its current [#basename][Athena::Framework::AbstractFile#basename] will be used.
  def move(directory : Path | String, name : String? = nil) : self
    target = self.target_file directory, name

    FileUtils.mv @path, target.path

    target
  end

  # Returns the contents of this file as a string.
  #
  # ```
  # file = ATH::File.new "/path/to/foo.txt"
  # file.content # => "foo" (content of foo.txt)
  # ```
  def content : String
    ::File.read @path
  end

  # Returns the last component of this file's path.
  # If *suffix* is present at the end of the path, it is removed.
  #
  # ```
  # file = ATH::File.new "/path/to/file.txt"
  # file.basename        # => "file.txt"
  # file.basename ".txt" # => "file"
  # ```
  def basename(suffix : String? = nil) : String
    suffix ? ::File.basename(@path, suffix) : ::File.basename(@path)
  end

  # Resolves the real path of this file by following symbolic links.
  #
  # ```
  # file = ATH::File.new "./../../etc/passwd"
  # file.realpath # => "/etc/passwd"
  # ```
  def realpath : String
    ::File.realpath @path
  end

  # Returns the size in bytes of this file.
  def size : Int
    ::File.size @path
  end

  # Returns the extension of this file, or an empty string if it does not have one.
  #
  # ```
  # file = ATH::File.new "/path/to/file.txt"
  # file.extname # => "txt"
  # ```
  def extname : String
    ::File.extname(@path).lchop '.'
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
