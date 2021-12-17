require "../spec_helper"

@[ADI::Register(tags: 42)]
class TaggedService
end

ADI::ServiceContainer.new
