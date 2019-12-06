require "../dependency_injection_spec_helper"

@[ADI::Register]
class TheService
end

@[ADI::Register("@the_service")]
class Klass
  include ADI::Service

  def initialize(@service : TheService); end
end

ADI::ServiceContainer.new
