require "../dependency_injection_spec_helper"

class TheService
  include ADI::Service
end

ADI::ServiceContainer.new
