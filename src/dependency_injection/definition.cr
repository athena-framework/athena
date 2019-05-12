require "../di"

module Athena::DI
  # Represents a registered service.
  struct Definition
    # The service instance.
    getter service : Athena::DI::Service

    # The tags belonging to this service.
    getter tags : Array(String) = [] of String

    def initialize(@service : Athena::DI::Service, @tags : Array(String) = [] of String); end
  end
end
