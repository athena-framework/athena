# An abstraction that allows representing a file without needing to keep the file open.
class Athena::MIME::Part::File
  class_getter mime_types : AMIME::Types { AMIME::Types.new }

  # Returns the path to the file on the filesystem.
  getter path : String

  def initialize(
    path : String | Path,
    @filename : String? = nil,
  )
    @path = path.to_s
  end

  # Attempts to guess the content type of the file based on its path.
  # Falls back to `application/octet-stream`.
  def content_type : String
    if mime_type = self.class.mime_types.mime_types(::File.extname(@path).lstrip('.')).first?
      return mime_type
    end

    "application/octet-stream"
  end

  # Returns the size of the file in bytes.
  def size : Int
    ::File.size @path
  end

  # Returns the name of the file, inferring it based on the basename of its path if not provided explicitly.
  def filename : String
    @filename ||= ::File.basename @path
  end
end
