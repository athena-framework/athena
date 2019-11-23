require "../dependency_injection_spec_helper"

@[Athena::DI::Register]
class Store < Athena::DI::ClassService
  property name : String = "Jim"
end

ADI::ServiceContainer.new.store
