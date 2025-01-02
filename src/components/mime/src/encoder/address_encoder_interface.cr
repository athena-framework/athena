module Athena::MIME::Encoder::AddressEncoderInterface
  abstract def encode(address : String) : String
end
