require "../di"

module Athena::DI
  # :nodoc:
  abstract struct ServiceDefinition; end

  # Represents a registered service.
  struct Definition(T) < Athena::DI::ServiceDefinition
    # The service instance
    getter service : Athena::DI::Service

    # The tags belonging to this service.
    getter tags : Array(String) = [] of String

    # The class of the service.
    getter service_class : T.class = T

    def initialize(@service : Athena::DI::Service, @tags : Array(String) = [] of String, service_class : T.class = T); end
  end
end
