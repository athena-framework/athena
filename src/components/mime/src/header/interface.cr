module Athena::MIME::Header::Interface
  abstract def name : String

  def body; end

  def body=(body); end

  abstract def max_line_length : Int32
  abstract def max_line_length=(max_line_length : Int32)

  # Render this header as a compliant string.
  abstract def to_s(io : IO) : Nil

  # Returns the header's body, prepared for folding into a final header value.
  #
  # This is not necessarily RFC 2822 compliant since folding white space is not added at this stage (see `#to_s` for that).
  def body_to_s : String
    String.build do |io|
      self.body_to_s io
    end
  end

  protected abstract def body_to_s(io : IO) : Nil
end
