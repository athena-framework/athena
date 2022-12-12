require "./event_dispatcher/*"

@[ADI::Register(name: "event_dispatcher", alias: AED::EventDispatcherInterface)]
class AED::EventDispatcher
end

ADI.auto_configure AED::EventListenerInterface, {tags: [ATH::Listeners::TAG]}
