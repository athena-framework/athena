require "uri/punycode"

struct Athena::MIME::Encoder::IDNAddress
  include Athena::MIME::Encoder::AddressEncoderInterface

  def encode(address : String) : String
    if address.includes? '@'
      local, _, domain = address.partition '@'

      unless domain.ascii_only?
        address = "#{local}@#{URI::Punycode.to_ascii domain}"
      end
    end

    address
  end
end
