require "uri/punycode"

# An IDNA encoder ([RFC 5980](https://datatracker.ietf.org/doc/html/rfc5980)), defined in [RFC 3492](https://datatracker.ietf.org/doc/html/rfc3492).
#
# Encodes the domain part of an address using IDN. This is compatible will all
# SMTP servers.
#
# NOTE: The local part is left as-is. In case there are non-ASCII characters
# in the local part then it depends on the SMTP Server if this is supported.
struct Athena::MIME::Encoder::IDNAddress
  include Athena::MIME::Encoder::AddressEncoderInterface

  # :inherit:
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
