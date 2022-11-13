@[ACONA::AsCommand("router:match", description: "Help debug routes by simulating a path match")]
@[ADI::Register]
# Similar to `ATH::Commands::DebugRouter`, but instead of providing the route name, you provide the request path
# in order to determine which, if any, route that path maps to.
#
# ```text
# $ ./bin/console router:match /user/10
#  [OK] Route 'example_controller_user' matches
#
# +--------------+-------------------------------------+
# | Property     | Value                               |
# +--------------+-------------------------------------+
# | Route Name   | example_controller_user             |
# | Path         | /user/{id}                          |
# | Path Regex   | ^/user/(?P<id>\d+)$                 |
# | Host         | ANY                                 |
# | Host Regex   |                                     |
# | Scheme       | ANY                                 |
# | Methods      | GET                                 |
# | Requirements | id: \d+                             |
# | Class        | Athena::Routing::Route              |
# | Defaults     | _controller: ExampleController#user |
# +--------------+-------------------------------------+
# ```
#
# Or if the route only partially matches:
#
# ```text
# $ ./bin/console router:match /user/foo
#  Route 'example_controller_user' almost matches but requirement for 'id' does not match (\d+)
#
#  [ERROR] None of the routes match the path '/user/foo'
# ```
class Athena::Framework::Commands::RouterMatch < ACON::Command
  def initialize(
    @router : ART::RouterInterface
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("path_info", :required, "A path to test")
      .option("method", nil, :required, "Set the HTTP method to use")
      .option("host", nil, :required, "Set the URI host")
      .option("scheme", nil, :required, "Set the URI scheme (usually http or https)")
      .help(
        <<-HELP
        The <info>%command.name%</info> shows which routes match a given request and which don't and for what reason:

          <info>%command.full_name% /foo</info>

        or

          <info>%command.full_name% /foo --method=POST --scheme=https --host=https://crystal-lang.org/ --verbose</info>
        HELP
      )
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = ACON::Style::Athena.new input, output

    context = @router.context

    if method = input.option "method"
      context.method = method
    end

    if scheme = input.option "scheme"
      context.scheme = scheme
    end

    if host = input.option "host"
      context.host = host
    end

    matcher = ART::Matcher::TraceableURLMatcher.new @router.route_collection, context

    traces = matcher.traces input.argument "path_info", String

    style.new_line

    matches = false

    traces.each do |trace|
      if trace.level.partial?
        style.text "Route <info>'#{trace.name}'</> almost matches but #{trace.message.sub 0, trace.message[0].downcase}}"
      elsif trace.level.full?
        style.success "Route '#{trace.name}' matches"

        router_debug_command = self.application.find("debug:router")
        router_debug_command.run ACON::Input::Hash.new({"name" => trace.name}), output

        matches = true
      else
        style.text "Route '#{trace.name}' does not match: #{trace.message}"
      end
    end

    unless matches
      style.error "None of the routes match the path '#{input.argument "path_info"}'"

      return Status::FAILURE
    end

    Status::SUCCESS
  end
end
