MAX_FILE_SIZE = 1024 * 1024 * 10 # 10 MiB

# :nodoc:
@[ADI::Register(public: true)]
class Athena::Framework::FileParser
  # Store the tmp uploaded paths to use to validate `ATH::UploadedFile`s.
  @uploaded_files : Set(String) = Set(String).new

  def parse(request : ATH::Request) : Nil
    HTTP::FormData.parse(request.request) do |part|
      next unless filename = part.filename.presence

      temp_dir = Path.new(Dir.tempdir, "athena").to_s
      Dir.mkdir_p temp_dir
      status : ATH::UploadedFile::Status = :ok

      temp_file = ::File.tempfile "file_upload.", nil, dir: temp_dir do |file|
        size = self.copy_with_max part.body, file
        status = :size_limit_exceeded if size.nil?
      end

      request.files[part.name] << UploadedFile.new temp_file.path, filename, part.headers["content-type"], status
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
      return if count > MAX_FILE_SIZE
    end
    count
  end
end
