@[ACONA::AsCommand("debug:event-dispatcher", description: "Display configured listeners for an application")]
@[ADI::Register]
# Utility command to allow viewing information about an `AED::EventDispatcherInterface`.
# Includes the type/method of each event listener, along with the order they run in based on their priority.
# Accepts an optional argument to allow filtering the list to a specific event, or ones that contain the provided string.
#
# ```text
# $ ./bin/console debug:event-dispatcher
# Registered Listeners Grouped by Event
# =====================================
#
# Athena::Framework::Events::Action event
# ---------------------------------------
#
#  ------- -------------------------------------------------------- ----------
#   Order   Callable                                                 Priority
#  ------- -------------------------------------------------------- ----------
#   #1      Athena::Framework::Listeners::ParamFetcher#on_action     5
#  ------- -------------------------------------------------------- ----------
#
# Athena::Framework::Events::Exception event
# ------------------------------------------
#
#  ------- -------------------------------------------------- ----------
#   Order   Callable                                           Priority
#  ------- -------------------------------------------------- ----------
#   #1      Athena::Framework::Listeners::Error#on_exception   -50
#  ------- -------------------------------------------------- ----------
#
# Athena::Framework::Events::Request event
# ----------------------------------------
#
#  ------- -------------------------------------------------- ----------
#   Order   Callable                                           Priority
#  ------- -------------------------------------------------- ----------
#   #1      Athena::Framework::Listeners::CORS#on_request      250
#   #2      Athena::Framework::Listeners::Format#on_request    34
#   #3      Athena::Framework::Listeners::Routing#on_request   32
#  ------- -------------------------------------------------- ----------
#
# ...
# ```
#
# TODO: Support dedicated `AED::EventDispatcherInterface` services other than the default.
class Athena::Framework::Commands::DebugEventDispatcher < ACON::Command
  def initialize(
    @dispatcher : AED::EventDispatcherInterface,
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("event", description: "An event name or a part of the event name") { @dispatcher.listeners.keys.map &.to_s }
      .option("format", value_mode: :required, description: "The output format (txt)", default: "txt") { ACON::Helper::Descriptor.new.formats }
      .option("raw", nil, :none, "To output raw command help")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = ACON::Style::Athena.new input, output

    # TODO: Allow resolving a specific dispatcher service
    dispatcher = @dispatcher

    event_class_map = dispatcher.listeners.each_key.each_with_object({} of String => AED::Event.class) do |event, map|
      map[event.to_s] = event
    end

    event_class = nil
    event_classes = nil

    if event = input.argument "event"
      e = event_class_map[event]?

      if e && dispatcher.has_listeners? e
        event_class = e
      else
        events = self.search_for_event dispatcher, event

        if events.empty?
          style.error_style.warning "The event '#{event}' does not have any registered listeners."

          return Status::SUCCESS
        elsif 1 == events.size
          event_class = events.first
        else
          event_classes = events
        end
      end
    end

    helper = Athena::Framework::Console::Helper::Descriptor.new

    helper
      .describe(
        style,
        dispatcher,
        ATH::Console::Descriptor::EventDispatcherContext.new(
          output: style,
          event_class: event_class,
          event_classes: event_classes,
          format: input.option("format", String),
          raw_text: input.option("raw", Bool),
        )
      )

    Status::SUCCESS
  end

  private def search_for_event(dispatcher : AED::EventDispatcherInterface, event : String) : Array(AED::Event.class)
    event_class_string = event.downcase

    matching_events = [] of AED::Event.class

    dispatcher.listeners.each_key.each do |event_class|
      matching_events << event_class if event_class.to_s.downcase.includes? event_class_string
    end

    matching_events
  end
end
