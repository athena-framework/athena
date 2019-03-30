module Athena::Routing::Handlers
  # Initializes the application's routes and kicks off the application's handlers.
  class RouteHandler
    include HTTP::Handler

    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    # ameba:disable Metrics/CyclomaticComplexity
    def initialize(@config : Athena::Config::Config)
      {% for c in Athena::Routing::Controller.all_subclasses %}
        {% methods = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% instance_methods = c.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_ann = c.annotation(Athena::Routing::ControllerOptions) %}

        # Raise compile time exception if a route is defined on a instance method.
        {% unless instance_methods.empty? %}
          {% raise "Routes can only be defined on class methods.  Did you mean 'self.#{instance_methods.first.name}'?" %}
        {% end %}

        {% _on_response = [] of CallbackBase %}
        {% _on_request = [] of CallbackBase %}

        # Build out the class's parent's callbacks
        {% parent_callbacks = [] of Def %}
        {% for parent in c.class.ancestors %}
          {% for callback in parent.methods.select { |me| me.annotation(Callback) } %}
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
          {% raise "Route action return type must be set for #{c.name}.#{m.name}" if m.return_type.stringify.empty? %}

          {% view_ann = m.annotation(View) %}
          {% param_converter = m.annotation(ParamConverter) %}

          # Ensure `type` implements the required method
          {% if param_converter && param_converter[:param] && param_converter[:type] && param_converter[:converter] %}
            {% if param_converter[:converter].stringify == "Exists" %}
              {% raise "#{param_converter[:type]} must implement a `self.find(id)` method to use the Exists converter." unless param_converter[:type].resolve.class.has_method?("find") %}
              {% raise "#{c.name}.#{m.name} #{param_converter[:converter]} converter requires a `pk_type` to be defined." unless param_converter[:pk_type] %}
            {% elsif param_converter[:converter].stringify == "RequestBody" %}
              {% raise "#{param_converter[:type]} must `include CrSerializer` or implement a `self.from_json(body : String) : self` method to use the RequestBody converter." unless param_converter[:type].resolve.class.has_method?("from_json") %}
            {% elsif param_converter[:converter].stringify == "FormData" %}
              {% raise "#{param_converter[:type]} implement a `self.from_form_data(form_data : HTTP::Params) : self` method to use the FormData converter." unless param_converter[:type].resolve.class.has_method?("from_form_data") %}
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

          {% prefix = class_ann && class_ann[:prefix] != nil ? (class_ann[:prefix].starts_with?('/') ? class_ann[:prefix] : "/" + class_ann[:prefix]) : "" %}
          {% path = (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}
          {% full_path = "/" + method + prefix + path %}
          {% cors_group = (route_def && route_def[:cors] ? route_def[:cors] : (class_ann && class_ann[:cors] ? class_ann[:cors] : nil)) %}

          {% params = [] of Param %}
          {% query_params = route_def[:query] ? route_def[:query] : [] of String %}

          # Build out the params array
          {% for arg in m.args %}
            # Path params
            {% for segment, idx in path.split('/') %}
              {% if segment =~ (/:\w+/) %}
                {% param_name = (segment.starts_with?(':') ? segment[1..-1] : (segment.starts_with?('(') ? segment[0..-2][2..-1] : segment)) %}
                {% if arg.name == param_name || arg.name == param_name.gsub(/_id$/, "") %}
                  {% params << "Athena::Routing::Parameters::PathParameter(#{arg.restriction}).new(#{param_name}, #{idx})".id %}
              {% end %}
              {% end %}
            {% end %}

            # Query params
            {% for name, pattern in query_params %}
              {% if arg.name == name %}
                {% params << "Athena::Routing::Parameters::QueryParameter(#{arg.restriction}).new(#{name}, #{pattern})".id %}
              {% end %}
            {% end %}

            # Body
            {% params << "Athena::Routing::Parameters::BodyParameter(#{arg.restriction}).new(\"body\")".id if arg.name == "body" && {"POST", "PUT"}.includes? method %}
          {% end %}

          {% constraints = route_def[:constraints] %}
          {% arg_types = m.args.map(&.restriction) %}

          {% groups = view_ann && view_ann[:groups] ? view_ann[:groups] : ["default"] %}
          {% renderer = view_ann && view_ann[:renderer] ? view_ann[:renderer] : "Athena::Routing::Renderers::JSONRenderer".id %}

            %action = ->(ctx : HTTP::Server::Context, vals : Hash(String, String?)) do
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
                ->{{c.name.id}}.{{m.name.id}}({{arg_types.splat}}).call(*Tuple({{arg_types.splat}}).from(arr))
              {% else %}
                ->{ {{c.name.id}}.{{m.name.id}} }.call
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
                {{params}} of Athena::Routing::Parameters::Param
              ){% if constraints %}, {{constraints}} {% end %}
        {% end %}
      {% end %}
    end

    def call(ctx : HTTP::Server::Context)
      # If this is a OPTIONS request change the method to the requested method to access the actual action that will be invoked.
      method : String = if (header = ctx.request.headers["Access-Control-Request-Method"]?) && ctx.request.method == "OPTIONS"
        header
      else
        ctx.request.method
      end

      search_key = '/' + method + ctx.request.path
      route = @routes.find search_key

      if route.found?
        action = route.payload.not_nil!
        action.controller.request = ctx.request
        action.controller.response = ctx.response
      else
        Athena::Routing::Controller.request = ctx.request
        Athena::Routing::Controller.response = ctx.response
        raise Athena::Routing::Exceptions::NotFoundException.new "No route found for '#{ctx.request.method} #{ctx.request.path}'"
      end

      call_next ctx, action, @config
    rescue ex
      if a = action
        a.controller.handle_exception ex, a.method
      else
        Athena::Routing::Controller.handle_exception ex, ctx.request.method
      end
    end
  end
end
