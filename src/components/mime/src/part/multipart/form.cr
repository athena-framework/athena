# Represents a `form-data` part.
class Athena::MIME::Part::Multipart::Form < Athena::MIME::Part::AbstractMultipart
  getter parts : Array(Athena::MIME::Part::Abstract) = Array(Athena::MIME::Part::Abstract).new

  def initialize(
    fields : Hash = {} of NoReturn => NoReturn,
  )
    super()

    self.headers.line_length = Int32::MAX
    self.prepare_fields fields
  end

  # :inherit:
  def media_sub_type : String
    "form-data"
  end

  private def prepare_fields(fields : Hash) : Nil
    fields.each do |k, v|
      self.visit_field k, v
    end
  end

  private def visit_field(key, value, root : String? = nil) : Nil
    field_name = root ? "#{root}[#{key}]" : key

    case value
    when Hash
      value.each do |k, v|
        self.visit_field k, v, field_name
      end

      return
    when Array
      value.each_with_index do |v, idx|
        self.visit_field idx.to_s, v, field_name
      end

      return
    when String, AMIME::Part::Text
      self.prepare_part field_name, value
    else
      raise AMIME::Exception::InvalidArgument.new "The value of the form field '#{field_name}' can only be a String, Hash, Array, or AMIME::Part::Text instance, got '#{value.class}'."
    end
  end

  private def prepare_part(name : String, value : String | AMIME::Part::Text) : Nil
    case value
    in String            then self.configure_part name, AMIME::Part::Text.new(value, encoding: "8bit")
    in AMIME::Part::Text then self.configure_part name, value
    end
  end

  private def configure_part(name : String, part : AMIME::Part::Text) : Nil
    part.name = name
    part.disposition = "form-data"
    part.headers.line_length = Int32::MAX
    part.encoding = "8bit"

    @parts << part
  end
end
