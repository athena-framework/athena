module Athena
  # Handles routing and param conversion on each request.
  class Athena::RouteHandler
    include HTTP::Handler

    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    def initialize
      {% for c in Athena::ClassController.all_subclasses + Athena::StructController.all_subclasses %}
        {% methods = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}

        _on_response = [] of CallbackBase
        _on_request = [] of CallbackBase

        # Set controller/global triggers
        {% for trigger in c.class.methods.select { |m| m.annotation(Callback) } + Athena::ClassController.class.methods.select { |m| m.annotation(Callback) } + Athena::StructController.class.methods.select { |m| m.annotation(Callback) } %}
          {% trigger_ann = trigger.annotation(Callback) %}
          {% only_actions = trigger_ann[:only] || "[] of String" %}
          {% exclude_actions = trigger_ann[:exclude] || "[] of String" %}
          {% if trigger_ann[:event].resolve == Athena::CallbackEvents::ON_RESPONSE %}
            _on_response << CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->{{c.name.id}}.{{trigger.name.id}}(HTTP::Server::Context), {{only_actions.id}}, {{exclude_actions.id}})
          {% elsif trigger_ann[:event].resolve == Athena::CallbackEvents::ON_REQUEST %}
            _on_request << CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->{{c.name.id}}.{{trigger.name.id}}(HTTP::Server::Context), {{only_actions.id}}, {{exclude_actions.id}})
          {% end %}
        {% end %}

      {% for m in methods %}
        {% raise "Route action return type must be set for #{c.name}.#{m.name}" if m.return_type.stringify.empty? %}
        {% view_ann = m.annotation(View) %}
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


        # Define routes
        {% path = "/" + method + (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}
        {% placeholder_count = path.chars.select { |chr| chr == ':' }.size %} # ameba:disable Performance/SizeAfterFilter
        {% raise "Expected #{c.name}.#{m.name} to have #{placeholder_count} method parameters, got #{m.args.size}.  Route's param count must match action's param count." if placeholder_count != (method == "GET" ? m.args.size : (m.args.size == 0 ? 0 : m.args.size - 1)) %}
        {% arg_types = m.args.map(&.restriction) %}
        {% arg_names = m.args.map(&.name) %}
        {% requirements = route_def[:requirements] %}
        {% arg_default_values = m.args.map { |a| a.default_value || nil } %}
        {% groups = view_ann ? view_ann[:groups] : ["default"] %}

          %proc = ->(vals : Array(String), context : HTTP::Server::Context) do
            {% unless m.args.empty? %}
              arr = Array(Union({{arg_types.splat}})).new
              {% for type, idx in arg_types %}
                {% converter = m.annotation(ParamConverter) %}
                {% if converter && converter[:param] == arg_names[idx] %}
                    arr << Athena::Converters::{{converter[:converter]}}({{converter[:type]}}).convert(vals[{{idx}}])
                {% else %}
                  {% if arg_default_values[idx] == nil %}
                    arr << Athena::Types.convert_type(vals[{{idx}}], {{type}})
                 {% else %}
                    arr << (vals[{{idx}}]? ? Athena::Types.convert_type(vals[{{idx}}], {{type}}) : {{arg_default_values[idx]}})
                  {% end %}
                {% end %}
              {% end %}
              ->{{c.name.id}}.{{m.name.id}}({{arg_types.splat}}).call(*Tuple({{arg_types.splat}}).from(arr))
            {% else %}
              ->{ {{c.name.id}}.{{m.name.id}} }.call
            {% end %}
          end
          @routes.add {{path}}, RouteAction(Proc(Array(String), HTTP::Server::Context, {{m.return_type}})).new(%proc, {{path}}, Callbacks.new(_on_response, _on_request), {{m.name.stringify}}, {{groups}}{% if requirements %}, {{requirements}} {% end %})
      {% end %}
    {% end %}
    end

    def call(context : HTTP::Server::Context)
      search_key = '/' + context.request.method + context.request.path
      route = @routes.find search_key

      unless route.found?
        halt context, 404, %({"code": 404, "message": "No route found for '#{context.request.method} #{context.request.path}'"})
        call_next context
        return
      end
      action = route.payload.not_nil!

      params = route.params.values.reverse

      if context.request.body && context.request.headers["Content-Type"]?.try(&.starts_with?("application/json"))
        params << context.request.body.not_nil!.gets_to_end
      end

      unless params.empty?
        placeholders = action.path.split('/').select { |str| str.starts_with? ':' }

        placeholders.each_with_index do |p, idx|
          regex : Regex? = action.requirements[p.lchop(':')]?
          next if regex.nil?
          unless params[idx] =~ regex
            halt context, 404, %({"code": 404, "message": "No route found for '#{context.request.method} #{context.request.path}'"})
            call_next context
            return
          end
        end
      end

      action.callbacks.on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(context)
        end
      end

      response = action.action.call params, context

      if response.is_a?(String)
        context.response.print response
      else
        context.response.print response.responds_to?(:serialize) ? response.serialize(action.groups) : response.to_json
      end

      action.callbacks.on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(context)
        end
      end
    rescue e : ArgumentError
      halt context, 400, %({"code": 400, "message": "#{e.message}"})
    rescue validation_exception : CrSerializer::Exceptions::ValidationException
      halt context, 400, validation_exception.to_json
    rescue not_found_exception : Athena::NotFoundException
      halt context, 404, not_found_exception.to_json
    rescue json_parse_exception : JSON::ParseException
      if msg = json_parse_exception.message
        if parts = msg.match(/Expected (\w+) but was (\w+) .*[\r\n]*.+#(\w+)/)
          halt context, 400, %({"code": 400, "message": "Expected #{parts[3]} to be #{parts[1]} but got #{parts[2]}"})
        end
      end
    end
  end
end
