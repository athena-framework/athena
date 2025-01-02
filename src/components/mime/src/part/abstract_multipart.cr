require "mime/multipart"

abstract class Athena::MIME::Part::AbstractMultipart < Athena::MIME::Part::Abstract
  private getter boundary : String { ::MIME::Multipart.generate_boundary }
  getter parts : Array(Athena::MIME::Part::Abstract) = [] of AMIME::Part::Abstract

  def self.new(*parts : AMIME::Part::Abstract) : self
    new parts
  end

  def initialize(parts : Enumerable(AMIME::Part::Abstract))
    parts.each do |part|
      @parts << part
    end
  end

  # :inherit:
  def media_type : String
    "multipart"
  end

  def prepared_headers : AMIME::Header::Collection
    headers = super

    headers.header_parameter "content-type", "boundary", self.boundary

    headers
  end

  # :inherit:
  # def inspect(io : IO)  : Nil
  #   super

  #   @parts.each do |part|
  #     part.inspect.each_line do |line|

  #     end
  #   end
  # end

  # :inherit:
  def body_to_s(io : IO) : Nil
    @parts.each do |part|
      io << self.boundary
      io << '\r' << '\n'
      part.to_s io
      io << '\r' << '\n'
    end

    io << self.boundary
    io << '\r' << '\n'
  end
end
