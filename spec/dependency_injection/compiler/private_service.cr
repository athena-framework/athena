require "../dependency_injection_spec_helper"

@[Athena::DI::Register]
class Store
  include ADI::Service

  property name : String = "Jim"
end

ADI::ServiceContainer.new.store
