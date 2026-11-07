class FileUploadController < ATH::Controller
  @[ARTA::Post("/required_single_file_present")]
  def required_single_file_present(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile) : String?
    file.client_original_name
  end

  @[ARTA::Post("/required_single_file_missing")]
  def required_single_file_missing(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile) : String?
    file.client_original_name
  end

  @[ARTA::Post("/required_single_file_missing_with_constraint")]
  def required_single_file_missing_with_constraint(
    @[ATHA::MapUploadedFile(constraints: AVD::Constraints::File.new(mime_types: ["text/plain"]))]
    file : AHTTP::UploadedFile,
  ) : String?
    file.client_original_name
  end

  @[ARTA::Post("/required_array_present")]
  def required_array_present(@[ATHA::MapUploadedFile] file : Array(AHTTP::UploadedFile)) : String?
    file.first.client_original_name
  end

  @[ARTA::Post("/required_array_empty")]
  def required_array_empty(@[ATHA::MapUploadedFile] file : Array(AHTTP::UploadedFile)) : String?
    file.first.client_original_name
  end

  @[ARTA::Post("/optional_single_file_present")]
  def optional_single_file_present(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : String?
    file.try &.client_original_name
  end

  @[ARTA::Post("/optional_single_file_missing")]
  def optional_single_file_missing(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : String?
    file.try &.client_original_name
  end

  @[ARTA::Post("/optional_single_file_missing_with_constraint")]
  def optional_single_file_missing_with_constraint(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : String?
    file.try &.client_original_name
  end

  @[ARTA::Post("/optional_array_present")]
  def optional_array_present(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : String?
    file.try &.client_original_name
  end

  @[ARTA::Post("/optional_array_empty")]
  def optional_array_empty(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : String?
    file.try &.client_original_name
  end

  @[ARTA::Post("/move_file")]
  def move_file(@[ATHA::MapUploadedFile] file : AHTTP::UploadedFile) : String
    moved_file = file.move Dir.tempdir, "athena_moved_upload.#{Random::Secure.hex 8}.txt"
    moved_file.content
  ensure
    moved_file.try { |f| ::File.delete? f.path }
  end
end
