module Athena::Routing
  # Handles routing and param conversion on each request.
  class RouteHandler
    include HTTP::Handler

    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    def initialize
      {% for c in Athena::Routing::ClassController.all_subclasses + Athena::Routing::StructController.all_subclasses %}
        {% methods = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% instance_methods = c.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}

        # Raise compile time exception if a route is defined on a instance method.
        {% unless instance_methods.empty? %}
          {% raise "Routes can only be defined on class methods.  Did you mean 'self.#{instance_methods.first.name}'?" %}
        {% end %}

        _on_response = [] of CallbackBase
        _on_request = [] of CallbackBase

        # Set controller/global triggers
        {% for trigger in c.class.methods.select { |m| m.annotation(Callback) } + Athena::Routing::ClassController.class.methods.select { |m| m.annotation(Callback) } + Athena::Routing::StructController.class.methods.select { |m| m.annotation(Callback) } %}
          {% trigger_ann = trigger.annotation(Callback) %}
          {% only_actions = trigger_ann[:only] || "[] of String" %}
          {% exclude_actions = trigger_ann[:exclude] || "[] of String" %}
          {% if trigger_ann[:event].resolve == Athena::Routing::CallbackEvents::OnResponse %}
            _on_response << CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->{{c.name.id}}.{{trigger.name.id}}(HTTP::Server::Context), {{only_actions.id}}, {{exclude_actions.id}})
          {% elsif trigger_ann[:event].resolve == Athena::Routing::CallbackEvents::OnRequest %}
            _on_request << CallbackEvent(Proc(HTTP::Server::Context, Nil)).new(->{{c.name.id}}.{{trigger.name.id}}(HTTP::Server::Context), {{only_actions.id}}, {{exclude_actions.id}})
          {% end %}
        {% end %}

        # Build out the routes
        {% for m in methods %}
          {% raise "Route action return type must be set for #{c.name}.#{m.name}" if m.return_type.stringify.empty? %}

          {% view_ann = m.annotation(View) %}
          {% param_converter = m.annotation(ParamConverter) %}

          # Ensure `type` implements the required method
          {% if param_converter && param_converter[:type] && param_converter[:converter] %}
            {% if param_converter[:converter].stringify == "Exists" %}
               {% raise "#{param_converter[:type]} must implement a `self.find(id)` method to use the Exists converter." unless param_converter[:type].resolve.class.has_method?("find") %}
            {% elsif param_converter[:converter].stringify == "RequestBody" %}
               {% raise "#{param_converter[:type]} must `include CrSerializer` or implement a `self.deserialize(body) : self` method to use the RequestBody converter." unless param_converter[:type].resolve.class.has_method?("deserialize") %}
            {% elsif param_converter[:converter].stringify == "FormData" %}
               {% raise "#{param_converter[:type]} implement a `self.from_form_data(form_data : HTTP::Params) : self` method to use the FormData converter." unless param_converter[:type].resolve.class.has_method?("from_form_data") %}
            {% end %}
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

          {% path = "/" + method + (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}

          {% arg_names = m.args.map(&.name.stringify) %}
          {% query_params = route_def[:query] ? route_def[:query].keys : "[]".id %}
          {% route_params = route_def[:path].split('/').select { |p| p.starts_with?(':') }.map { |v| v.tr(":", "") } %}
          {% arg_names.all? { |pa| (query_params + route_params).any? { |v| v == pa } || raise "#{c.name}.#{m.name} parameter '#{pa.id}' is not defined in route or query parameters." }  %}
          {% raise "#{c.name}.#{m.name} has #{arg_names.size} parameters defined, while there are #{(query_params + route_params).size} route and query parameters defined.  Did you forget to add one?" if arg_names.size != (query_params + route_params).size %}

          {% arg_types = m.args.map(&.restriction) %}
          {% arg_default_values = m.args.map { |a| a.default_value || nil } %}
          {% constraints = route_def[:constraints] %}
          {% query_params = [] of Param %}
          {% if route_def && route_def[:query] %}
            {% for name, pattern, idx in route_def[:query] %}
              {% query_params << "QueryParam(#{arg_types[-(idx+1)]}).new(#{name}, #{pattern})".id %}
            {% end %}
          {% end %}
          {% groups = view_ann && view_ann[:groups] ? view_ann[:groups] : ["default"] %}
          {% renderer = view_ann && view_ann[:renderer] ? view_ann[:renderer] : "JSONRenderer".id %}

            %proc = ->(vals : Hash(String, String?)) do
              {% unless m.args.empty? %}
                arr = Array(Union({{arg_types.splat}}, Nil)).new
                {% for type, idx in arg_types %}
                  {% if param_converter && param_converter[:converter] && param_converter[:type] && param_converter[:param] == arg_names[idx] %}
                      arr << Athena::Routing::Converters::{{param_converter[:converter]}}({{param_converter[:type]}}).convert(vals[{{arg_names[idx].stringify}}])
                  {% else %}
                    arr << if val = vals[{{arg_names[idx].stringify}}]?
                       Athena::Types.convert_type(val, {{type}})
                    else
                      {{arg_default_values[idx]}}
                    end
                  {% end %}
                {% end %}
                ->{{c.name.id}}.{{m.name.id}}({{arg_types.splat}}).call(*Tuple({{arg_types.splat}}).from(arr))
              {% else %}
                ->{ {{c.name.id}}.{{m.name.id}} }.call
              {% end %}
            end
            @routes.add {{path}}, RouteAction(Proc(Hash(String, String?), {{m.return_type}}), Athena::Routing::Renderers::{{renderer}}({{m.return_type}})).new(%proc, {{path}}, Callbacks.new(_on_response, _on_request), {{m.name.stringify}}, {{groups}}, {{query_params}} of Param){% if constraints %}, {{constraints}} {% end %}
        {% end %}
      {% end %}
    end

    def call(context : HTTP::Server::Context)
      search_key = '/' + context.request.method + context.request.path
      route = @routes.find search_key

      unless route.found?
        halt context, 404, %({"code": 404, "message": "No route found for '#{context.request.method} #{context.request.path}'"})
      end
      action = route.payload.not_nil!

      params = Hash(String, String?).new

       params.merge! route.params

      if context.request.body
        if content_type = context.request.headers["Content-Type"]? || "text/plain"
          body : String = context.request.body.not_nil!.gets_to_end
          case content_type.downcase
          when "application/json", "text/plain", "application/x-www-form-urlencoded"
            params["body"] = body
          else
            halt context, 415, %({"code": 415, "message": "Invalid Content-Type: '#{content_type.downcase}'"})
          end
        end
      end

      if reuest_params = context.request.query
        query_params = HTTP::Params.parse reuest_params
        action.query_params.each do |qp|
          if val = query_params[qp.name]?
            params[qp.name] = (pat = qp.pattern) ? (val =~ pat ? val : nil) : val
          else
            halt context, 400, %({"code": 400, "message": "Required query param '#{qp.name}' was not supplied."}) unless qp.type.nilable?
          end
        end
      else
        action.query_params.each do |qp|
          halt context, 400, %({"code": 400, "message": "Required query param '#{qp.name}' was not supplied."}) unless qp.type.nilable? 
          params[qp.name] = nil
        end
      end

      action.as(RouteAction).callbacks.on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(context)
        end
      end

      response = action.as(RouteAction).action.call params

      context.response.print response.is_a?(String) ? response : action.as(RouteAction).renderer.render response, action, context

      action.as(RouteAction).callbacks.on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(context)
        end
      end
    rescue e : ArgumentError
      halt context, 400, %({"code": 400, "message": "#{e.message}"})
    rescue validation_exception : CrSerializer::Exceptions::ValidationException
      halt context, 400, validation_exception.to_json
    rescue not_found_exception : Athena::Routing::NotFoundException
      halt context, 404, not_found_exception.to_json
    rescue json_parse_exception : JSON::ParseException
      if msg = json_parse_exception.message
        if parts = msg.match(/Expected (\w+) but was (\w+) .*[\r\n]*.+#(\w+)/)
          halt context, 400, %({"code": 400, "message": "Expected '#{parts[3]}' to be #{parts[1]} but got #{parts[2]}"})
        end
      end
    end
  end
end
