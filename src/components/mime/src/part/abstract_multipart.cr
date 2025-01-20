require "mime/multipart"

# Base type of all *multipart* based parts.
abstract class Athena::MIME::Part::AbstractMultipart < Athena::MIME::Part::Abstract
  private getter boundary : String { ::MIME::Multipart.generate_boundary }

  # Returns the parts that make up this multipart part.
  getter parts : Array(Athena::MIME::Part::Abstract) = [] of AMIME::Part::Abstract

  def self.new(*parts : AMIME::Part::Abstract) : self
    new parts
  end

  def initialize(parts : Enumerable(AMIME::Part::Abstract) = [] of AMIME::Part::Abstract)
    parts.each do |part|
      @parts << part
    end
  end

  # :inherit:
  def media_type : String
    "multipart"
  end

  # :inherit:
  def prepared_headers : AMIME::Header::Collection
    headers = super

    headers.header_parameter "content-type", "boundary", self.boundary

    headers
  end

  protected def body_to_s(io : IO) : Nil
    self.parts.each do |part|
      io << self.boundary
      io << '\r' << '\n'
      part.to_s io
      io << '\r' << '\n'
    end

    io << self.boundary
    io << '\r' << '\n'
  end
end
