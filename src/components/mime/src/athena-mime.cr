require "./address"
require "./message"
require "./email"
require "./draft_email"

require "./encoder/*"
require "./exception/*"
require "./header/*"
require "./part/*"
require "./part/multipart/*"

# Convenience alias to make referencing `Athena::MIME` types easier.
alias AMIME = Athena::MIME

module Athena::MIME
  VERSION = "0.1.0"

  module Encoder; end

  # Both acts as a namespace for exceptions related to the `Athena::MIME` component, as well as a way to check for exceptions from the component.
  module Exception; end

  module Header; end

  module Part; end
end
