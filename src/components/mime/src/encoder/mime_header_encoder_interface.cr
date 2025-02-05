# Represents an encoder responsible for encoding the value of MIME headers.
module Athena::MIME::Encoder::MIMEHeaderEncoderInterface
  # Returns the name of this content encoding scheme.
  abstract def name : String
end
