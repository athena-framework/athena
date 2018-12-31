module Athena
  class Athena::RouteHandler
    include HTTP::Handler

    @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

    def initialize
      {% for c in Athena::ClassController.all_subclasses + Athena::StructController.all_subclasses %}
      {% methods = c.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) } %}
      {% for m in methods %}
        {% raise "Route action return type must be set for #{c.name}.#{m.name}" if m.return_type.stringify.empty? %}
        {% if d = m.annotation(Get) %}
          {% method = "GET" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Post) %}
          {% method = "POST" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Put) %}
          {% method = "PUT" %}
          {% route_def = d %}
        {% end %}

        {% path = "/" + method + (route_def[:path].stringify.starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}
        {% arg_types = m.args.map(&.restriction) %}
        {% arg_names = m.args.map(&.name) %}
        {% requirements = route_def[:requirements] %}
        {% arg_default_values = m.args.map { |a| a.default_value || nil } %}
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
          @routes.add {{path}}, RouteAction(Proc(Array(String), HTTP::Server::Context, {{m.return_type}})).new(%proc, {{path}} {% if requirements %}, {{requirements}} {% end %})
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
      action : Action = route.payload.not_nil!
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

      response = action.action.call params, context

      if response.is_a?(String)
        context.response.print response
      else
        context.response.print response.responds_to?(:serialize) ? response.serialize : response.to_json
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
