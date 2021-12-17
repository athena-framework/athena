require "../spec_helper"

@[ADI::Register(tags: [{priority: 42}])]
class TaggedService
end

ADI::ServiceContainer.new
