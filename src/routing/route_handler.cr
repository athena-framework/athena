module Athena::Routing
  # Handles routing and param conversion on each request.
  class RouteHandler
    include HTTP::Handler

    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    def initialize
      {% for c in Athena::Routing::ClassController.all_subclasses + Athena::Routing::StructController.all_subclasses %}
        {% methods = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% instance_methods = c.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_ann = c.annotation(Athena::Routing::Controller) %}

        # Raise compile time exception if a route is defined on a instance method.
        {% unless instance_methods.empty? %}
          {% raise "Routes can only be defined on class methods.  Did you mean 'self.#{instance_methods.first.name}'?" %}
        {% end %}

        _on_response = [] of CallbackBase
        _on_request = [] of CallbackBase

        # Build out the class's parent's callbacks
        {% parent_callbacks = [] of Def %}
        {% for parent in c.class.ancestors %}
          {% for callback in parent.methods.select { |me| me.annotation(Callback) } %}
            {% parent_callbacks << callback %}
          {% end %}
        {% end %}

        # Set controller/global triggers
        {% for trigger in c.class.methods.select { |m| m.annotation(Callback) } + parent_callbacks + Athena::Routing::ClassController.class.methods.select { |m| m.annotation(Callback) } + Athena::Routing::StructController.class.methods.select { |m| m.annotation(Callback) } %}
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
          {% if param_converter && param_converter[:type] && param_converter[:param_type] && param_converter[:converter] %}
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


          {% prefix = class_ann && class_ann[:prefix] != nil ? (class_ann[:prefix].starts_with?('/') ? class_ann[:prefix] : "/" + class_ann[:prefix]) : "" %}
          {% path = "/" + method + prefix + (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}

          {% arg_names = m.args.map(&.name.stringify) %}
          {% query_params = route_def[:query] ? route_def[:query].keys : [] of String %}
          {% route_params = route_def[:path].split('/').select { |p| p.starts_with?(':') || (p.starts_with?("(:") && p.ends_with?(')')) }.map { |v| v.includes?('(') ? v.tr("(:", "").tr(")", "") : v.tr(":", "") } %}
          {% route_params << "body" if %w(POST PUT).includes? method %}
          {% arg_names.all? { |pa| (query_params + route_params).any? { |v| v == pa || v.tr("_id", "") == pa } || raise "#{c.name}.#{m.name} parameter '#{pa.id}' is not defined in route or query parameters." } %}
          {% raise "#{c.name}.#{m.name} has #{arg_names.size} parameters defined, while there are #{(query_params + route_params).size} route and query parameters defined.  Did you forget to add one?" if (query_params + route_params).size != arg_names.size %}

          {% arg_types = m.args.map(&.restriction) %}
          {% arg_default_values = m.args.map { |a| a.default_value || nil } %}
          {% constraints = route_def[:constraints] %}
          {% query_params = ["QueryParam(Nil).new(\"placeholder\", nil)".id] %}

          {% if body_param = m.args.find { |a| a.name.stringify == "body" } %}
            {% body_type = body_param.restriction %}
          {% else %}
            {% body_type = Nil %}
          {% end %}

          {% if route_def && route_def[:query] %}
            {% for name, pattern, idx in route_def[:query] %}
              {% if arg = m.args.find { |a| a.name.stringify == name } %}
                  {% query_params << "QueryParam(#{arg.restriction}).new(#{name}, #{pattern})".id %}
              {% end %}
            {% end %}
          {% end %}

          {% groups = view_ann && view_ann[:groups] ? view_ann[:groups] : ["default"] %}
          {% renderer = view_ann && view_ann[:renderer] ? view_ann[:renderer] : "JSONRenderer".id %}

            %proc = ->(vals : Hash(String, String?)) do
              {% unless m.args.empty? %}
                arr = Array(Union({{arg_types.splat}}, Nil)).new
                {% for type, idx in arg_types %}
                    key = if vals.has_key? {{arg_names[idx]}}
                      {{arg_names[idx]}}
                    elsif vals.has_key? {{arg_names[idx] + "_id"}}
                      {{arg_names[idx] + "_id"}}
                    end
                    arr << if val = vals[key]?
                    {% if param_converter && param_converter[:converter] && param_converter[:type] && param_converter[:param] == arg_names[idx] %}
                      Athena::Routing::Converters::{{param_converter[:converter]}}({{param_converter[:type]}}, {{param_converter[:param_type] ? param_converter[:param_type] : Nil}}).convert val
                    {% else %}
                      Athena::Types.convert_type val, {{type}}
                    {% end %}
                    else
                      {{arg_default_values[idx]}}
                    end
                {% end %}
                ->{{c.name.id}}.{{m.name.id}}({{arg_types.splat}}).call(*Tuple({{arg_types.splat}}).from(arr))
              {% else %}
                ->{ {{c.name.id}}.{{m.name.id}} }.call
              {% end %}
            end
            @routes.add {{path}}, RouteAction(Proc(Hash(String, String?), {{m.return_type}}), Athena::Routing::Renderers::{{renderer}}({{m.return_type}}), {{body_type}}).new(%proc, {{path}}, Callbacks.new(_on_response.uniq, _on_request.uniq), {{m.name.stringify}}, {{groups}}, {{query_params}} of Param){% if constraints %}, {{constraints}} {% end %}
        {% end %}
      {% end %}
    end

    def call(ctx : HTTP::Server::Context)
      search_key = '/' + ctx.request.method + ctx.request.path
      route = @routes.find search_key

      halt ctx, 404, %({"code": 404, "message": "No route found for '#{ctx.request.method} #{ctx.request.path}'"}) unless route.found?

      action = route.payload.not_nil!
      params = Hash(String, String?).new

      params.merge! route.params

      if ctx.request.body
        if content_type = ctx.request.headers["Content-Type"]? || "text/plain"
          body : String = ctx.request.body.not_nil!.gets_to_end
          case content_type.downcase
          when "application/json", "text/plain", "application/x-www-form-urlencoded"
            params["body"] = body
          else
            halt ctx, 415, %({"code": 415, "message": "Invalid Content-Type: '#{content_type.downcase}'"})
          end
        end
      else
        halt ctx, 400, %({"code": 400, "message": "Request body was not supplied."}) if !action.body_type.nilable? && action.body_type != Nil
      end

      if reuest_params = ctx.request.query
        query_params = HTTP::Params.parse reuest_params

        action.query_params.each do |qp|
          next if qp.name == "placeholder"
          if val = query_params[qp.as(QueryParam).name]?
            params[qp.as(QueryParam).name] = if pat = qp.as(QueryParam).pattern
                                               if val =~ pat
                                                 val
                                               else
                                                 halt ctx, 400, %({"code": 400, "message": "Expected query param '#{qp.as(QueryParam).name}' to match '#{pat}' but got '#{val}'"}) unless qp.as(QueryParam).type.nilable?
                                               end
                                             else
                                               val
                                             end
          else
            halt ctx, 400, %({"code": 400, "message": "Required query param '#{qp.as(QueryParam).name}' was not supplied."}) unless qp.as(QueryParam).type.nilable?
          end
        end
      else
        action.query_params.each do |qp|
          next if qp.name == "placeholder"
          halt ctx, 400, %({"code": 400, "message": "Required query param '#{qp.as(QueryParam).name}' was not supplied."}) unless qp.as(QueryParam).type.nilable?
          params[qp.as(QueryParam).name] = nil
        end
      end

      action.as(RouteAction).callbacks.on_request.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end

      response = action.as(RouteAction).action.call params

      ctx.response.print action.as(RouteAction).renderer.render response, ctx, action.groups

      action.as(RouteAction).callbacks.on_response.each do |ce|
        if (ce.as(CallbackEvent).only_actions.empty? || ce.as(CallbackEvent).only_actions.includes?(action.as(RouteAction).method)) && (ce.as(CallbackEvent).exclude_actions.empty? || !ce.as(CallbackEvent).exclude_actions.includes?(action.method))
          ce.as(CallbackEvent).event.call(ctx)
        end
      end
    rescue e : ArgumentError
      halt ctx, 400, %({"code": 400, "message": "#{e.message}"})
    rescue validation_exception : CrSerializer::Exceptions::ValidationException
      halt ctx, 400, validation_exception.to_json
    rescue not_found_exception : Athena::Routing::NotFoundException
      halt ctx, 404, not_found_exception.to_json
    rescue json_parse_exception : JSON::ParseException
      if msg = json_parse_exception.message
        if parts = msg.match(/Expected (\w+) but was (\w+) .*[\r\n]*.+#(\w+)/)
          halt ctx, 400, %({"code": 400, "message": "Expected '#{parts[3]}' to be #{parts[1]} but got #{parts[2]}"})
        end
      end
    end
  end
end
