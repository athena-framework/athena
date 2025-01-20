# Represents a `mixed` part.
class Athena::MIME::Part::Multipart::Mixed < Athena::MIME::Part::AbstractMultipart
  # :inherit:
  def media_sub_type : String
    "mixed"
  end
end
