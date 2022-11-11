@[ACONA::AsCommand("debug:router", description: "Display current routes for an application")]
@[ADI::Register]
class Athena::Framework::Commands::DebugRouter < ACON::Command
  def initialize(
    @router : ART::RouterInterface
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("name", :optional, "A route name")
      .option("show-controllers", nil, :none, "Show assigned controllers in overview")
      .option("format", nil, :required, "The output format (txt)", "txt")
      .option("raw", nil, :none, "To output raw command help")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    helper = Athena::Framework::Console::Helper::Descriptor.new
    routes = @router.route_collection

    style = ACON::Style::Athena.new input, output

    if name = input.argument "name"
      route = routes[name]?
      matching_routes = self.find_route_name_containing name, routes

      if !input.interactive? && !route && !matching_routes.empty?
        helper
          .describe(
            style,
            self.find_route_containing(name, routes),
            ATH::Console::Descriptor::RoutingContext.new(
              output: style,
              show_controllers: input.option("show-controllers", Bool),
              format: input.option("format", String),
              raw_text: input.option("raw", Bool),
            )
          )

        return Status::SUCCESS
      end

      if !route && !matching_routes.empty?
        default = (1 == matching_routes.size) ? matching_routes.first : nil
        name = style.choice("Select one of the matching routes", matching_routes, default).as String
        route = routes[name]
      end

      if !route
        raise ACON::Exceptions::InvalidArgument.new "The route '#{name}' does not exist."
      end

      helper
        .describe(
          style,
          route,
          ATH::Console::Descriptor::RoutingContext.new(
            name: name,
            output: style,
            format: input.option("format", String),
            raw_text: input.option("raw", Bool),
          )
        )
    else
      helper
        .describe(
          style,
          routes,
          ATH::Console::Descriptor::RoutingContext.new(
            output: style,
            show_controllers: input.option("show-controllers", Bool),
            format: input.option("format", String),
            raw_text: input.option("raw", Bool),
          )
        )
    end

    Status::SUCCESS
  end

  private def find_route_name_containing(name : String, routes : ART::RouteCollection) : Array(String)
    routes.compact_map do |route_name, _|
      next unless route_name.includes? name

      route_name
    end
  end

  private def find_route_containing(name : String, routes : ART::RouteCollection) : ART::RouteCollection
    found_routes = ART::RouteCollection.new

    routes.each do |route_name, route|
      found_routes.add route_name, route if route_name.includes? name
    end

    found_routes
  end
end
