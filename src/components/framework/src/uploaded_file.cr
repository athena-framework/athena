struct Athena::Framework::UploadedFile
  enum Status
    OK
  end

  getter path : String

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
end
