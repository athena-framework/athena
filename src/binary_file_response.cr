require "./response"
require "digest/sha256"
require "mime"

class Athena::Routing::BinaryFileResponse < Athena::Routing::Response
  getter file_path : Path

  @offset : Int32 = 0
  @max_length : Int32? = nil
  setter delete_file_after_send : Bool = false

  enum ContentDisposition
    Attachment
    Inline
  end

  def initialize(
    file_path : String | Path,
    status : HTTP::Status | Int32 = HTTP::Status::OK,
    headers : HTTP::Headers = HTTP::Headers.new,
    public : Bool = true,
    content_disposition : ART::BinaryFileResponse::ContentDisposition = :attachment,
    auto_etag : Bool = false,
    auto_last_modified : Bool = true
  )
    super nil, status, headers

    raise File::Error.new("File '#{file_path}' must be readable.", file: file_path.to_s) unless File.readable? file_path

    @file_path = Path.new(file_path).expand

    self.set_public if public
    self.set_auto_etag if auto_etag
    self.auto_last_modified if auto_last_modified
    self.set_content_disposition content_disposition if content_disposition
  end

  def content=(_data) : Nil
    raise "The content cannot be set on a BinaryFileResponse instance."
  end

  def content : String
    ""
  end

  # :inherit:
  def write(output : IO) : Nil
    unless @status.success?
      super output
      return
    end

    if @max_length.try &.zero?
      return
    end

    @writer.write(output) do |writer_io|
      File.open(@file_path, "rb") do |file|
        file.skip @offset

        if limit = @max_length
          IO.copy file, writer_io, limit
        else
          IO.copy file, writer_io
        end
      end
    end

    if @delete_file_after_send && File.file?(@file_path)
      File.delete @file_path
    end
  end

  def set_content_disposition(disposition : ART::BinaryFileResponse::ContentDisposition, file_name : String? = nil)
    if file_name.nil?
      file_name = File.basename @file_path
    end

    disposition_header = String.build do |io|
      disposition.to_s.downcase io

      io << "; filename=\""
      HTTP.quote_string(file_name, io)
      io << '"'
    end

    @headers["content-disposition"] = disposition_header
  end

  def set_auto_etag : Nil
    self.set_etag Digest::SHA256.base64digest { |ctx| ctx.file @file_path }
  end

  def auto_last_modified : Nil
    self.last_modified = File.info(@file_path).modification_time
  end

  # TODO: Support multiple ranges
  protected def prepare(request : HTTP::Request) : Nil
    unless @headers.has_key? "content-type"
      @headers["content-type"] = MIME.from_filename(@file_path.to_s, "application/octet-stream")
    end

    file_size = File.info(@file_path).size

    @headers["Content-Length"] = file_size.to_s

    unless @headers.has_key? "accept-ranges"
      @headers["accept-ranges"] = request.safe? ? "bytes" : "none"
    end

    if request.headers.has_key?("range") && "GET" == request.method
      if !request.headers.has_key?("if-range") || self.valid_if_range_header?(request.headers["if-range"]?)
        if range = request.headers["range"].lchop? "bytes="
          s, e = range.split('-', 2)

          e = e.empty? ? file_size - 1 : e.to_i

          if s.empty?
            s = file_size - e
            e = file_size - 1
          else
            s = s.to_i
          end

          if s <= e
            e = Math.min e, file_size - 1

            if s < 0 || s > e
              self.status = :range_not_satisfiable
              @headers["content-range"] = "bytes */#{file_size}"
            elsif e - s < file_size - 1
              @max_length = e < file_size ? (e - s + 1).to_i : nil
              @offset = s.to_i

              self.status = :partial_content
              @headers["content-range"] = "bytes #{s}-#{e}/#{file_size}"
              @headers["content-length"] = "#{e - s + 1}"
            end
          end
        end
      end
    end
  end

  private def valid_if_range_header?(header : String?) : Bool
    return true if self.etag == header

    return false unless last_modified = self.last_modified

    Time::Format::HTTP_DATE.format(last_modified) == header
  end
end
