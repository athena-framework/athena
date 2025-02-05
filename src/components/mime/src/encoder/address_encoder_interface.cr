# Represents an encoder responsible for encoding an email address.
module Athena::MIME::Encoder::AddressEncoderInterface
  # Returns an encoded version of the provided *address*.
  abstract def encode(address : String) : String
end
