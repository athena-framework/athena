require "./ext/conversion_types"

require "./abstract_file"
require "./binary_file_response"
require "./file"
require "./header_utils"
require "./ip_utils"
require "./parameter_bag"
require "./redirect_response"
require "./response"
require "./response_headers"
require "./request"
require "./request_matcher"
require "./request_store"
require "./streamed_response"
require "./uploaded_file"

require "./exception/*"
require "./request_matcher/*"

# Convenience alias to make referencing `Athena::HTTP` types easier.
alias AHTTP = Athena::HTTP

module Athena::HTTP
  VERSION = "0.1.0"

  # Both acts as a namespace for exceptions related to the `Athena::HTTP` component, as well as a way to check for exceptions from the component.
  module Exception; end
end
