require "../spec_helper"

@[ADI::Register(tags: [true])]
class TaggedService
end

ADI::ServiceContainer.new
