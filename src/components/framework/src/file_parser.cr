# :nodoc:
class Athena::Framework::FileParser
  # Store the tmp uploaded paths to use to validate `ATH::UploadedFile`s.
  @uploaded_files : Set(String) = Set(String).new

  protected class_getter default_temp_dir : String do
    temp_dir = Path.new Dir.tempdir, "athena"
    Dir.mkdir_p temp_dir
    temp_dir.to_s
  end

  def initialize(
    temp_dir : String?,
    @max_uploads : Int32,
    @max_file_size : Int64,
  )
    @temp_dir = temp_dir || self.class.default_temp_dir
  end

  def parse(request : ATH::Request) : Nil
    uploaded_file_count = 0

    HTTP::FormData.parse(request.request) do |part|
      unless filename = part.filename.presence
        request.attributes.set part.name, part.body.gets_to_end, String
        next
      end

      next if uploaded_file_count >= @max_uploads

      status : ATH::UploadedFile::Status = :ok

      size : Int64? = 0

      temp_file = ::File.tempfile "file_upload.", nil, dir: @temp_dir do |file|
        size = self.copy_with_max part.body, file
      end

      file_path = temp_file.path

      if size.nil?
        status = :size_limit_exceeded
        temp_file.delete
        file_path = ""
      end

      if status.ok?
        @uploaded_files << file_path
      end

      request.files[part.name] << UploadedFile.new file_path, filename, part.headers["content-type"]?, status
      uploaded_file_count += 1
    end
  end

  def clear : Nil
    @uploaded_files.each do |tmp_uploaded_file_path|
      ::File.delete? tmp_uploaded_file_path
    rescue ex
      Log.warn(exception: ex) { "Failed to cleanup temp file upload: '#{tmp_uploaded_file_path}'." }
    end
  end

  protected def uploaded_file?(path : String) : Bool
    @uploaded_files.includes? path
  end

  # Based off of https://github.com/crystal-lang/crystal/blob/54022594f84040c976634863ce5fac1b31a68048/src/io.cr#L1173
  # but returns `nil` if more bytes than allowed were written.
  private def copy_with_max(src : IO, dest : IO) : Int64?
    buffer = uninitialized UInt8[IO::DEFAULT_BUFFER_SIZE]
    count = 0_i64
    while (len = src.read(buffer.to_slice).to_i32) > 0
      dest.write buffer.to_slice[0, len]
      count &+= len
      return if count > @max_file_size
    end
    count
  end
end
