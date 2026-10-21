require "http/headers"
require "http/status"
require "http/server/response"

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
require "./session"
require "./session/bag_interface"
require "./session/attribute_bag"
require "./session/flash_bag"
require "./session/factory"
require "./session/storage/interface"
require "./session/storage/factory_interface"
require "./session/storage"
require "./session/storage/factory"
require "./session/storage/metadata_bag"
require "./session/storage/handler/interface"
require "./session/storage/handler/abstract_handler"
require "./session/storage/handler/*"
require "./streamed_response"
require "./uploaded_file"

require "./exception/*"
require "./request_matcher/*"

# Convenience alias to make referencing `Athena::HTTP` types easier.
alias AHTTP = Athena::HTTP

module Athena::HTTP
  VERSION = "0.1.1"

  # Both acts as a namespace for exceptions related to the `Athena::HTTP` component, as well as a way to check for exceptions from the component.
  module Exception; end
end
