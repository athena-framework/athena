struct Athena::Framework::UploadedFile
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
  getter status : ATH::UploadedFile::Status

  def initialize(
    path : String | Path,
    @original_name : String,
    @mime_type : String?,
    @status : ATH::UploadedFile::Status = :ok,
    @test : Bool = false,
  )
    @path = path.to_s
  end

  def client_original_name : String
    @original_name
  end

  def valid? : Bool
    is_ok = @status.ok?

    @test ? is_ok : is_ok && self.uploaded_file?
  end

  # This is an anti-pattern but I can't think of a better way to handle it
  # without making this DTO type depend upon a service.
  #
  # Or requiring DI in the validator component.
  private def uploaded_file?
    return false if (path = @path).empty?
    ADI.container.athena_framework_file_parser.uploaded_file? path
  end
end
