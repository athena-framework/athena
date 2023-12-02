# Includes various `HTTP` header utility methods.
module Athena::Framework::HeaderUtils
  # Generates a `HTTP` [content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header value with the provided *disposition* and *filename*.
  #
  # If *filename* contains non `ASCII` characters, a sanitized version will be used as part of the `filename` directive,
  # while an encoded version of it will be used as the `filename*` directive.
  # The *fallback_filename* argument can be used to customize the `filename` directive value in this case.
  #
  # ```
  # ATH::HeaderUtils.make_disposition :attachment, "download.txt"         # => attachment; filename="download.txt"
  # ATH::HeaderUtils.make_disposition :attachment, "föö.html"             # => attachment; filename="f__.html"; filename*=UTF-8''f%C3%B6%C3%B6.html
  # ATH::HeaderUtils.make_disposition :attachment, "föö.html", "foo.html" # => attachment; filename="foo.html"; filename*=UTF-8''f%C3%B6%C3%B6.html
  # ```
  #
  # This method can be used to enable downloads of dynamically generated files.
  # I.e. that can't be handled via a static file event listener.
  #
  # ```
  # ATH::Response.new(
  #   file_contents,
  #   headers: HTTP::Headers{"content-disposition" => ATH::HeaderUtils.make_disposition(:attachment, "foo.pdf")}
  # )
  # ```
  #
  # TIP: Checkout the [external documentation](../../getting_started/README.md#static-files) for an example of how to serve static files.
  def self.make_disposition(disposition : ATH::BinaryFileResponse::ContentDisposition, filename : String, fallback_filename : String? = nil) : String
    if fallback_filename.nil? && (!filename.ascii_only? || filename.includes?('%'))
      fallback_filename = filename.gsub { |chr| chr.ascii? ? chr : '_' }
    end

    if fallback_filename.nil?
      fallback_filename = filename
    end

    # The `%` character isn't valid in the fallback filename.
    if fallback_filename.includes? '%'
      raise ArgumentError.new "The fallback filename cannot contain the '%' character."
    end

    # The fallback filename may not contain path separators.
    if {'/', '\\'}.any? { |s| filename.includes? s }
      raise ArgumentError.new "The filename cannot include path separators."
    elsif {'/', '\\'}.any? { |s| fallback_filename.includes? s }
      raise ArgumentError.new "The fallback filename cannot include path separators."
    end

    params = {
      "filename" => fallback_filename,
    }

    if filename != fallback_filename
      params["filename*"] = "UTF-8''#{URI.encode_path_segment filename}"
    end

    String.build do |io|
      disposition.to_s.downcase io
      io << "; "

      self.to_string io, params, "; "
    end
  end

  def self.parse(header : String) : Hash(String, String | Bool)
    values = Hash(String, String | Bool).new

    header.strip.scan /(?:[^,\"]*+(?:"[^"]*+\")?)+[^,\"]*+/ do |match|
      match_string = match[0].strip

      next if match_string.blank?

      if match_string.includes? '='
        key, value = match_string.split '='
        values[key] = value
      else
        values[match_string] = true
      end
    end

    values
  end

  # Joins the provided key/value *parts* into a string for use within an `HTTP` header.
  #
  # The key and value of each entry is joined with `=`, quoting the value if needed.
  # All entries are then joined by the provided *separator*.
  def self.to_string(separator : String | Char, **parts) : String
    self.to_string parts.to_h, separator
  end

  # Joins a key/value pair *collection* into a string for use within an `HTTP` header.
  #
  # The key and value of each entry is joined with `=`, quoting the value if needed.
  # All entries are then joined by the provided *separator*.
  #
  # ```
  # ATH::HeaderUtils.to_string({"foo" => "bar", "key" => true}, ", ")          # => foo=bar, key
  # ATH::HeaderUtils.to_string({"foo" => %q("foo\ bar"), "key" => true}, ", ") # => foo=\"foo\\\ bar\", key
  # ```
  def self.to_string(collection : Hash, separator : String | Char) : String
    String.build do |io|
      self.to_string io, collection, separator
    end
  end

  # Joins a key/value pair *collection* for use within an `HTTP` header; writing the data to the provided *io*.
  #
  # The key and value of each entry is joined with `=`, quoting the value if needed.
  # All entries are then joined by the provided *separator*.
  def self.to_string(io : IO, collection : Hash, separator : String | Char) : Nil
    collection.join(io, separator) do |(k, v), join_io|
      if true == v
        join_io << k
      else
        join_io << k << '='
        HTTP.quote_string v.to_s, join_io
      end
    end
  end
end
