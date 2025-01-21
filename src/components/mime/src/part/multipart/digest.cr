# Represents a `digest` part.
class Athena::MIME::Part::Multipart::Digest < Athena::MIME::Part::AbstractMultipart
  # :inherit:
  def media_sub_type : String
    "digest"
  end
end
