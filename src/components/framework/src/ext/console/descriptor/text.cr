# :nodoc:
class Athena::Framework::Console::Descriptor::Text < Athena::Framework::Console::Descriptor
  protected def describe(route : ART::Route, context : ATH::Console::Descriptor::RoutingContext) : Nil
    defaults = route.defaults

    headers = %w(Property Value)
    rows = [
      ["Route Name", context.name],
      ["Path", route.path],
      ["Path Regex", route.compile.regex.source],
      ["Host", (host = route.host) ? host : "ANY"],
      ["Host Regex", !route.host.nil? ? route.compile.host_regex.try(&.source) : ""],
      ["Scheme", (schemes = route.schemes) ? schemes.join('|') : "ANY"],
      ["Methods", (methods = route.methods) ? methods.join('|') : "ANY"],
      ["Requirements", !(requirements = route.requirements).empty? ? self.format_router_config(requirements) : "NO CUSTOM"],
      ["Class", route.class.to_s],
      ["Defaults", self.format_router_config(defaults)],
    ]

    ACON::Helper::Table.new(self.output)
      .headers(headers)
      .rows(rows)
      .render
  end

  protected def describe(routes : ART::RouteCollection, context : ATH::Console::Descriptor::RoutingContext) : Nil
    show_controllers = context.show_controllers?

    headers = %w(Name Method Scheme Host Path)
    headers << "Controller" if show_controllers

    rows = routes.map do |name, route|
      controller = route.default "_controller"

      row = [
        name,
        (methods = route.methods) ? methods.join('|') : "ANY",
        (schemes = route.schemes) ? schemes.join('|') : "ANY",
        (host = route.host) ? host : "ANY",
        route.path,
      ]

      if show_controllers && controller
        row << controller
      end

      row
    end

    if output = context.output
      output.as(ACON::Style::Athena).table(headers, rows)
    else
      ACON::Helper::Table.new(self.output)
        .headers(headers)
        .rows(rows)
        .render
    end
  end

  private def format_router_config(config : Hash) : String
    return "" if config.empty?

    # Sort hash via key.
    config = config
      .to_a
      .sort! { |(n1, _), (n2, _)| n1 <=> n2 }
      .to_h

    String.build do |io|
      config.each do |key, value|
        io << '\n'
        io << key
        io << ':' << ' '
        io << case value
        when Regex then value.source
        else
          value
        end
      end
    end.strip
  end

  protected def describe(event_dispatcher : AED::EventDispatcherInterface, context : EventDispatcherContext) : Nil
    # TODO: Support specific dispatcher services

    title = "Registered Listeners"

    if event = context.event_class
      title = "#{title} for the #{event} Event"
      listeners = event_dispatcher.listeners event
    else
      title = "#{title} Grouped by Event"
      listeners = if events = context.event_classes
                    events.each_with_object({} of AED::Event.class => Array(AED::Callable)) do |ec, map|
                      map[ec] = event_dispatcher.listeners ec
                    end
                  else
                    event_dispatcher.listeners
                  end
    end

    output = context.output.as ACON::Style::Athena

    output.title title

    self.render_event_listener_table output, event_dispatcher, listeners
  end

  private def render_event_listener_table(
    output : ACON::Style::Athena,
    event_dispatcher : AED::EventDispatcherInterface,
    event_listeners : Hash(AED::Event.class, Array(AED::Callable))
  ) : Nil
    sorted_listeners = event_listeners
      .to_a
      .sort! { |(n1, _), (n2, _)| n1.to_s <=> n2.to_s }
      .to_h

    sorted_listeners.each do |event, el|
      output.section "#{event} event"
      self.render_event_listener_table output, event_dispatcher, el
    end
  end

  private def render_event_listener_table(
    output : ACON::Style::Athena,
    event_dispatcher : AED::EventDispatcherInterface,
    event_listeners : Array(AED::Callable)
  ) : Nil
    table_headers = %w(Order Callable Priority)
    table_rows = [] of Array(String | Int32)

    event_listeners.each_with_index do |callable, idx|
      table_rows << ["##{idx + 1}", callable.name, callable.priority]
    end

    output.table table_headers, table_rows
  end
end
