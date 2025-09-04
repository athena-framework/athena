require "./address"
require "./message"
require "./email"
require "./draft_email"

require "./message_converter"

require "./encoder/*"
require "./exception/*"
require "./header/*"
require "./part/*"
require "./part/multipart/*"
require "./types"
require "./magic_types_guesser"
require "./native_types_guesser"

# Convenience alias to make referencing `Athena::MIME` types easier.
alias AMIME = Athena::MIME

# Allows manipulating the MIME messages used to send emails and provides utilities related to MIME types.
module Athena::MIME
  VERSION = "0.2.1"

  # Namespace for types related to encoding part of the MIME message.
  module Encoder; end

  # Both acts as a namespace for exceptions related to the `Athena::MIME` component, as well as a way to check for exceptions from the component.
  module Exception; end

  # Namespace for the types used to represent MIME headers.
  module Header; end

  # Namespace for the types used to represent the parts used to compose a MIME message.
  module Part
    # Namespace for Multipart related parts.
    module Multipart; end
  end
end
