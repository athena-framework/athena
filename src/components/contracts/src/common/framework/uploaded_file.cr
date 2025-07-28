require "file_utils"
require "./file"

struct Athena::Framework::UploadedFile < Athena::Framework::AbstractFile
  enum Status
    OK
    SIZE_LIMIT_EXCEEDED
  end

  class_getter max_file_size : Int64 { 0_i64 }

  # :nodoc:
  #
  # Is expected to be set internally based on framework configuration value.
  def self.max_file_size=(@@max_file_size : Int64) : Nil; end

  getter path : String
  getter status : Athena::Framework::UploadedFile::Status

  def initialize(
    path : String | Path,
    @original_name : String,
    mime_type : String?,
    @status : Athena::Framework::UploadedFile::Status = :ok,
    @test : Bool = false,
  )
    @path = path.to_s
    @mime_type = mime_type || "application/octet-stream"
  end

  # Returns the original name of the file as determined by the client.
  # It should not be considered a safe value to use for a file on your server.
  def client_original_name : String
    @original_name
  end

  # Returns the original extension of the file as determined by the client.
  def client_original_extension : String
    File.extname @original_name
  end

  # Returns the original full file path as determined by the client.
  # It should not be considered a safe value to use for a file name/path on your server.
  #
  # If the file was uploaded with the `webkitdirectory` directive, this will contain the path of the file relative to the uploaded root directory.
  # Otherwise will be identical to `#client_original_name`.
  def client_original_path : String
    self.client_original_name
  end

  # Returns the file's MIME type as determined by the client.
  # It should not be considered as a safe value.
  #
  # For a trusted MIME type, use `#mime_type` which guesses the MIME type based on the file's contents).
  def client_mime_type : String
    @mime_type
  end

  # Returns the extension based on the client MIME type, or `nil` if the MIME type is unknown.
  # This method uses `#client_mime_type`, and as such should not be trusted.
  #
  # For a trusted extension, use `#guess_extension` which guesses the extension based on the guessed MIME type for the file).
  def guess_client_extension : String?
    AMIME::Types.default.extensions(self.client_mime_type).first?
  end

  def valid? : Bool
    is_ok = @status.ok?

    @test ? is_ok : is_ok && self.uploaded_file?
  end

  def move(directory : Path | String, name : String? = nil) : Athena::Framework::File
    if self.valid?
      return super
    end

    case @status
    when .size_limit_exceeded? then raise Athena::Framework::Exception::FileTooBig.new self.path
    end
  end

  def error_message : String
    original_name = self.client_original_name

    case @status
    when .size_limit_exceeded? then "The file '#{original_name}' exceeds your max_file_size configuration value (limit is #{self.class.max_file_size.humanize_bytes})."
    else
      "The file '#{original_name}' was not uploaded due to an unknown error."
    end
  end

  # This is an anti-pattern but I can't think of a better way to handle it
  # without making this DTO type depend upon a service.
  #
  # Or requiring DI in the validator component.
  private def uploaded_file?
    return false if (path = @path).empty?

    container = ADI.container

    if container.responds_to? :athena_framework_file_parser
      return container.athena_framework_file_parser.uploaded_file? path
    end

    false
  end
end
