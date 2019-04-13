require "./handler"

module Athena::Routing::Handlers
  # Initializes the application's routes and kicks off the application's handlers.
  class RouteHandler < Athena::Routing::Handlers::Handler
    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    def handle(ctx : HTTP::Server::Context, action : Action, config : Athena::Config::Config) : Nil; end

    # ameba:disable Metrics/CyclomaticComplexity
    def initialize(@config : Athena::Config::Config)
      {% for c in Athena::Routing::Controller.all_subclasses %}
        {% methods = c.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_actions = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_ann = c.annotation(Athena::Routing::ControllerOptions) %}

        # Raise compile time exception if a route is defined as a class method.
        {% unless class_actions.empty? %}
          {% raise "Routes can only be defined as instance methods.  Did you mean '#{class_actions.first.name}' within #{c.name}?" %}
        {% end %}

        {% instance_callbacks = c.methods.select { |m| m.annotation(Callback) } %}

        # Raise compile time exception if a callback is defined as an instance method.
        {% unless instance_callbacks.empty? %}
          {% raise "Controller callbacks can only be defined as class methods.  Did you mean 'self.#{instance_callbacks.first.name}' within #{c.name}?" %}
        {% end %}

        # Raise compile time exception if handle_exceptions is defined as an instance method.
        {% if c.methods.map(&.name.stringify).includes? "handle_exception" %}
          {% raise "Exception handlers can only be defined as class methods. Did you mean 'self.handle_exception' within #{c.name}?" %}
        {% end %}

        {% _on_response = [] of CallbackBase %}
        {% _on_request = [] of CallbackBase %}
        {% cors_group = nil %}

        {% parent_prefix = "" %}

        # Build out the class's parent's callbacks
        {% parent_callbacks = [] of Def %}
        {% for parent in c.ancestors %}
          {% parent_ann = parent.annotation(Athena::Routing::ControllerOptions) %}
          {% if cors_group == nil && parent_ann && parent_ann[:cors] != nil %}
            {% cors_group = parent_ann[:cors] %}
          {% end %}
          {% if parent_ann && parent_ann[:prefix] != nil %}
            {% parent_prefix = (parent_ann[:prefix].starts_with?('/') ? parent_ann[:prefix] : "/" + parent_ann[:prefix]) + parent_prefix %}
          {% end %}
          {% for callback in parent.class.methods.select { |me| me.annotation(Callback) } %}
            {% parent_callbacks.unshift callback %}
          {% end %}
        {% end %}

        # Set Global > Parent > Controller callbacks
        {% for callback in (Athena::Routing::Controller.class.methods.select { |m| m.annotation(Callback) } + parent_callbacks + c.class.methods.select { |m| m.annotation(Callback) }) %}
          {% callback_ann = callback.annotation(Callback) %}
          {% only_actions = callback_ann[:only] || "[] of String" %}
          {% exclude_actions = callback_ann[:exclude] || "[] of String" %}
          {% if callback_ann[:event].resolve == Athena::Routing::CallbackEvents::OnResponse %}
            {% _on_response << "CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->#{c.name.id}.#{callback.name.id}(HTTP::Server::Context), #{only_actions.id}, #{exclude_actions.id})".id %}
          {% elsif callback_ann[:event].resolve == Athena::Routing::CallbackEvents::OnRequest %}
            {% _on_request << "CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->#{c.name.id}.#{callback.name.id}(HTTP::Server::Context), #{only_actions.id}, #{exclude_actions.id})".id %}
          {% end %}
        {% end %}

        # Build out the routes
        {% for m in methods %}
          {% raise "Route action return type must be set for '#{c.name}##{m.name}'" if m.return_type.stringify.empty? %}

          {% view_ann = m.annotation(View) %}
          {% param_converter = m.annotation(ParamConverter) %}

          # Ensure `type` implements the required method
          {% if param_converter && param_converter[:param] && param_converter[:type] && param_converter[:converter] %}
            {% if param_converter[:converter].stringify == "Exists" %}
              {% raise "#{param_converter[:type]} must implement a `self.find(id)` method to use the Exists converter." unless param_converter[:type].resolve.class.has_method?("find") %}
              {% raise "#{c.name}.#{m.name} #{param_converter[:converter]} converter requires a `pk_type` to be defined." unless param_converter[:pk_type] %}
            {% elsif param_converter[:converter].stringify == "RequestBody" %}
              {% raise "#{param_converter[:type]} must `include CrSerializer` to use the RequestBody converter." unless param_converter[:type].resolve.class.has_method?("from_json") %}
            {% elsif param_converter[:converter].stringify == "FormData" %}
              {% raise "#{param_converter[:type]} must implement a `self.from_form_data(form_data : HTTP::Params) : self` method to use the FormData converter." unless param_converter[:type].resolve.class.has_method?("from_form_data") %}
            {% end %}
          {% elsif param_converter %}
            {% raise "#{c.name}.#{m.name} ParamConverter annotation is missing a required field.  Must specifiy `param`, `type`, and `converter`." %}
          {% end %}

          {% if d = m.annotation(Get) %}
            {% method = "GET" %}
            {% route_def = d %}
          {% elsif d = m.annotation(Post) %}
            {% method = "POST" %}
            {% route_def = d %}
          {% elsif d = m.annotation(Put) %}
            {% method = "PUT" %}
            {% route_def = d %}
          {% elsif d = m.annotation(Delete) %}
            {% method = "DELETE" %}
            {% route_def = d %}
          {% end %}

          # Set and normalize the prefix if one exists
          {% prefix = class_ann && class_ann[:prefix] ? parent_prefix + (class_ann[:prefix].starts_with?('/') ? class_ann[:prefix] : "/" + class_ann[:prefix]) : parent_prefix %}

          # Normalize the path
          {% path = (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}

          # Build out full path
          {% full_path = "/" + method + prefix + path %}

          # Set the cors_group if defined, otherwise use parent's
          {% cors_group = (route_def && route_def[:cors] != nil ? route_def[:cors] : (class_ann && class_ann[:cors] != nil ? class_ann[:cors] : cors_group)) %}

          # Get array of path/query params for error handling
          {% route_params = (prefix + path).split('/').select { |p| p =~ (/:(\w+)/) }.map { |p| p.tr("(:)", "") } %}
          {% query_params = route_def[:query] ? route_def[:query] : {} of String => Regex? %}

          {% action_params = m.args.map(&.name.stringify) %}

          {% for p in (query_params.keys + route_params + ({"POST", "PUT"}.includes?(method) ? ["body"] : [] of String)) %}
            {% raise "'#{p.id}' is defined in #{c.name}##{m.name} path/query parameters but is missing from action arguments." if !(action_params.includes?(p.gsub(/_id$/, "")) || action_params.includes?(p)) %}
          {% end %}

          {% params = [] of Param %}

          # Build out the params array
          {% for arg in m.args %}
            {% found = false %}
            # Path params
            {% for segment, idx in (prefix + path).split('/') %}
              {% if segment =~ (/:\w+/) %}
                {% param_name = (segment.starts_with?(':') ? segment[1..-1] : (segment.starts_with?('(') ? segment[0..-2][2..-1] : segment)) %}
                {% if arg.name == param_name || arg.name == param_name.gsub(/_id$/, "") %}
                  {% params << "Athena::Routing::Parameters::PathParameter(#{arg.restriction}).new(#{param_name}, #{idx})".id %}
                  {% found = true %}
                {% end %}
              {% end %}
            {% end %}

            # Query params
            {% for name, pattern, idx in query_params %}
              {% if arg.name == name %}
                {% params << "Athena::Routing::Parameters::QueryParameter(#{arg.restriction}).new(#{name}, #{pattern})".id %}
                {% found = true %}
              {% end %}
            {% end %}

            # Body
            {% if {"POST", "PUT"}.includes? method %}
              {% if arg.name == "body" %}
                {% params << "Athena::Routing::Parameters::BodyParameter(#{arg.restriction}).new(\"body\")".id %}
                {% found = true %}
              {% end %}
            {% end %}
            {% raise "'#{arg.name}' is defined in #{c.name}##{m.name} action arguments but is missing from path/query parameters." unless found %}
          {% end %}

          {% constraints = route_def[:constraints] %}
          {% arg_types = m.args.map(&.restriction) %}

          {% groups = view_ann && view_ann[:groups] ? view_ann[:groups] : ["default"] %}
          {% renderer = view_ann && view_ann[:renderer] ? view_ann[:renderer] : "Athena::Routing::Renderers::JSONRenderer".id %}

            %action = ->(ctx : HTTP::Server::Context, vals : Hash(String, String?)) do
              instance = {{c.id}}.new(ctx)
              # If there are no args, just call the action.  Otherwise build out an array of values to pass to the action.
              {% unless m.args.empty? %}
                arr = Array(Union({{arg_types.splat}}, Nil)).new
                {% for arg in m.args %}
                    key = if vals.has_key? {{arg.name.stringify}}
                      {{arg.name.stringify}}
                    elsif vals.has_key? {{arg.name.stringify + "_id"}}
                      {{arg.name.stringify + "_id"}}
                    end
                    arr << if val = vals[key]?
                    {% if param_converter && param_converter[:converter] && param_converter[:type] && param_converter[:param] == arg.name.stringify %}
                      Athena::Routing::Converters::{{param_converter[:converter]}}({{param_converter[:type]}}, {{param_converter[:pk_type] ? param_converter[:pk_type] : Nil}}).convert ctx, val
                    {% else %}
                      Athena::Types.convert_type val, {{arg.restriction}}
                    {% end %}
                    else
                      {{arg.default_value || nil}}
                    end
                    {% end %}
                ->instance.{{m.name.id}}({{arg_types.splat}}).call(*Tuple({{arg_types.splat}}).from(arr))
              {% else %}
                ->{ instance.{{m.name.id}} }.call
              {% end %}
            end
            @routes.add {{full_path}}, RouteAction(
              Proc(HTTP::Server::Context, Hash(String, String?), {{m.return_type}}), {{renderer}}, {{c.id}})
              .new(
                %action,
                RouteDefinition.new({{full_path}}, {{cors_group}}),
                Callbacks.new({{_on_response.uniq}} of CallbackBase, {{_on_request.uniq}} of CallbackBase),
                {{m.name.stringify}},
                {{groups}},
                {% unless params.empty? %} {{params}} of Athena::Routing::Parameters::Param {% end %}
              ){% if constraints %}, {{constraints}} {% end %}
        {% end %}
      {% end %}
    end

    def call(ctx : HTTP::Server::Context)
      # If this is a OPTIONS request change the method to the requested method to access the actual action that will be invoked.
      method : String = if ctx.request.method == "OPTIONS"
        if header = ctx.request.headers["Access-Control-Request-Method"]?
          header
        else
          raise Athena::Routing::Exceptions::ForbiddenException.new "Preflight request header 'Access-Control-Request-Method' is missing."
        end
      else
        ctx.request.method
      end

      search_key = '/' + method + ctx.request.path
      route = @routes.find search_key
      action = route.found? ? route.payload.not_nil! : raise Athena::Routing::Exceptions::NotFoundException.new "No route found for '#{ctx.request.method} #{ctx.request.path}'"

      call_next ctx, action, @config
    rescue ex
      if a = action
        a.controller.handle_exception ex, ctx
      else
        Athena::Routing::Controller.handle_exception ex, ctx
      end
    end
  end
end
