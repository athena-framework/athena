MAX_FILE_SIZE = 1024 * 1024 * 10 # 10 MiB

@[ADI::Register]
struct Athena::Framework::Listeners::File
  @[AEDA::AsEventListener]
  def on_request(event : ATH::Events::Request) : Nil
    return unless event.request.headers["content-type"]?.try &.starts_with? "multipart/form-data"

    HTTP::FormData.parse(event.request.request) do |part|
      next unless filename = part.filename.presence

      temp_dir = Path.new(Dir.tempdir, "athena").to_s
      Dir.mkdir_p temp_dir

      temp_file = ::File.tempfile "file_upload.", nil, dir: temp_dir do |file|
        size = self.copy_with_max part.body, file

        raise "Oh noes" if size.nil?
      end

      event.request.files[part.name] << UploadedFile.new temp_file.path, filename, part.headers["content-type"]
    end
  end

  @[AEDA::AsEventListener]
  def on_terminate(event : ATH::Events::Terminate) : Nil
    return if (files = event.request.files).empty?

    files.each_value do |uploaded_files|
      uploaded_files.each do |uploaded_file|
        ::File.delete? uploaded_file.path
      rescue ex
        Log.warn(exception: ex) { "Failed to cleanup temp file upload: '#{uploaded_file.path}'." }
      end
    end
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
