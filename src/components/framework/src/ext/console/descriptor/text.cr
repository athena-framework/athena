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
end
