require "./response"
require "digest/sha256"
require "mime"

# Represents a static file that should be returned the client; includes various options to enhance the response headers. See `.new` for details.
#
# This response supports [Range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) requests
# and [Conditional](https://developer.mozilla.org/en-US/docs/Web/HTTP/Conditional_requests) requests via the
# [If-None-Match](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match),
# [If-Modified-Since](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since),
# and [If-Range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range) headers.
#
# See `ATH::HeaderUtils.make_disposition` for an example of handling dynamic files.
class Athena::Framework::BinaryFileResponse < Athena::Framework::Response
  # Returns a `Path` instance representing the file that will be sent to the client.
  getter file_path : Path

  # Determines if the file should be deleted after being sent to the client.
  setter delete_file_after_send : Bool = false

  @offset : Int64 = 0
  @max_length : Int64? = nil

  # Represents the possible [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header values.
  enum ContentDisposition
    # Indicates that the file should be downloaded.
    Attachment

    # Indicates that the browser should display the file inside the Web page, or as the Web page.
    Inline

    # :inherit:
    def to_s(io : IO) : Nil
      case self
      in .attachment? then io << "attachment"
      in .inline?     then io << "inline"
      end
    end
  end

  # Instantiates `self` wrapping the file at the provided *file_path*, optionally with the provided *status*, and *headers*.
  #
  # By default the response is `ATH::Response#set_public` and includes a `last-modified` header,
  # but these can be controlled via the *public* and *auto_last_modified* arguments respectively.
  #
  # The *content_disposition* argument can be used to set the `content-disposition` header on `self` if it should be downloadable.
  #
  # The *auto_etag* argument can be used to automatically set `ETag` header based on a `SHA256` hash of the file.
  def initialize(
    file_path : String | Path,
    status : HTTP::Status | Int32 = HTTP::Status::OK,
    headers : HTTP::Headers | ATH::Response::Headers = ATH::Response::Headers.new,
    public : Bool = true,
    content_disposition : ATH::BinaryFileResponse::ContentDisposition? = nil,
    auto_etag : Bool = false,
    auto_last_modified : Bool = true
  )
    super nil, status, headers

    raise File::Error.new("File '#{file_path}' must be readable.", file: file_path) unless File::Info.readable? file_path

    @file_path = Path.new(file_path).expand

    self.set_public if public
    self.set_auto_etag if auto_etag
    self.auto_last_modified if auto_last_modified
    self.set_content_disposition content_disposition if content_disposition
  end

  # CAUTION: Cannot set the response content via this method on `self`.
  def content=(data) : Nil
    raise "The content cannot be set on a BinaryFileResponse instance." unless data.nil?
  end

  # CAUTION: Cannot get the response content via this method on `self`.
  def content : String
    ""
  end

  # Sets the `content-disposition` header on `self` to the provided *disposition*.
  # *filename* defaults to the basename of `#file_path`.
  #
  # See `ATH::HeaderUtils.make_disposition`.
  def set_content_disposition(disposition : ATH::BinaryFileResponse::ContentDisposition, filename : String? = nil, fallback_filename : String? = nil)
    if filename.nil?
      filename = @file_path.basename
    end

    @headers["content-disposition"] = ATH::HeaderUtils.make_disposition disposition, filename, fallback_filename
  end

  # Sets the `etag` header on `self` based on a `SHA256` hash of the file.
  def set_auto_etag : Nil
    self.set_etag Digest::SHA256.base64digest &.file(@file_path)
  end

  # Sets the `last-modified` header on `self` based on the modification time of the file.
  def auto_last_modified : Nil
    self.last_modified = File.info(@file_path).modification_time
  end

  # TODO: Support multiple ranges.
  # TODO: Support `X-Sendfile`.
  #
  # OPTIMIZE: Make this less complex.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  protected def prepare(request : ATH::Request) : Nil
    if self.cache_request?(request)
      self.status = :not_modified
      return super
    end

    unless @headers.has_key? "content-type"
      @headers["content-type"] = MIME.from_filename(@file_path, "application/octet-stream")
    end

    file_size = File.info(@file_path).size

    @headers["content-length"] = file_size.to_s

    unless @headers.has_key? "accept-ranges"
      @headers["accept-ranges"] = request.safe? ? "bytes" : "none"
    end

    if request.headers.has_key?("range") && "GET" == request.method
      if !request.headers.has_key?("if-range") || self.valid_if_range_header?(request.headers["if-range"]?)
        if range = request.headers["range"].lchop? "bytes="
          s, e = range.split '-', 2

          e = e.empty? ? file_size - 1 : e.to_i64

          if s.empty?
            s = file_size - e
            e = file_size - 1
          else
            s = s.to_i64
          end

          if s <= e
            e = Math.min e, file_size - 1

            if s < 0 || s > e
              self.status = :range_not_satisfiable
              @headers["content-range"] = "bytes */#{file_size}"
            elsif e - s < file_size - 1
              @max_length = e < file_size ? (e - s + 1).to_i64 : nil
              @offset = s.to_i64

              self.status = :partial_content
              @headers["content-range"] = "bytes #{s}-#{e}/#{file_size}"
              @headers["content-length"] = "#{e - s + 1}"
            end
          end
        end
      end
    end
  end

  protected def write(output : IO) : Nil
    unless @status.success?
      return super output
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

  private def cache_request?(request : ATH::Request) : Bool
    # According to RFC 7232:
    # A recipient must ignore If-Modified-Since if the request contains an If-None-Match header field
    if (if_none_match = request.if_none_match) && (etag = self.etag)
      match = {"*", etag}
      if_none_match.any? { |et| match.includes? et }
    elsif if_modified_since = request.headers["if-modified-since"]?
      header_time = HTTP.parse_time if_modified_since
      last_modified = self.last_modified || File.info(@file_path).modification_time

      # File mtime probably has a higher resolution than the header value.
      # An exact comparison might be slightly off, so we add 1s padding.
      # Static files should generally not be modified in subsecond intervals, so this is perfectly safe.
      !!(header_time && last_modified <= header_time + 1.second)
    else
      false
    end
  end

  private def valid_if_range_header?(header : String?) : Bool
    return true if self.etag == header

    return false unless last_modified = self.last_modified

    HTTP.format_time(last_modified) == header
  end
end
