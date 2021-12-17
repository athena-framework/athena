require "../spec_helper"

@[ADI::Register]
class Service
  property name : String = "Jim"
end

ADI::ServiceContainer.new.service
