require "mime"

class Athena::MIME::Part::File
  getter path : String

  def initialize(
    path : String | Path,
    @filename : String? = nil
  )
    @path = path.to_s
  end

  def content_type : String
    if mime_type = ::MIME.from_filename?(@path)
      return mime_type
    end

    "application/octet-stream"
  end

  def size : Int32
    ::File.size @path
  end

  def filename : String
    @filename ||= ::File.basename @path
  end
end
