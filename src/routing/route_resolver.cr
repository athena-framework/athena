class Athena::Routing::RouteResolver
  @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

  def initialize
    {% for klass, c_idx in Athena::Routing::Controller.all_subclasses %}
        {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_ann = klass.annotation(Athena::Routing::ControllerOptions) %}

        # Raise compile time exception if a route is defined as a class method.
        {% unless class_actions.empty? %}
          {% raise "Routes can only be defined as instance methods.  Did you mean '#{class_actions.first.name}' within #{klass.name}?" %}
        {% end %}

        # Raise compile time exception if handle_exceptions is defined as an instance method.
        {% if klass.methods.map(&.name.stringify).includes? "handle_exception" %}
          {% raise "Exception handlers can only be defined as class methods. Did you mean 'self.handle_exception' within #{klass.name}?" %}
        {% end %}

        {% parent_prefix = "" %}

        %instance{c_idx} = {{klass.id}}.new

        # Build out the routes
        {% for m in methods %}
          {% raise "Route action return type must be set for '#{klass.name}##{m.name}'" if m.return_type.is_a? Nop %}

          {% view_ann = m.annotation(View) %}
          {% param_converters = m.annotations(ParamConverter) %}

          {% for converter in param_converters %}
            # Ensure each converter implements required properties and `type` implements the required methods.
            {% if converter && converter[:param] && converter[:type] && converter[:converter] %}
              {% if converter[:converter].stringify == "Exists" %}
                {% raise "#{converter[:type]} must implement a `self.find(id)` method to use the Exists converter." unless converter[:type].resolve.class.has_method?("find") %}
                {% raise "#{klass.name}.#{m.name} #{converter[:converter]} converter requires a `pk_type` to be defined." unless converter[:pk_type] %}
              {% elsif converter[:converter].stringify == "RequestBody" %}
                {% raise "#{converter[:type]} must `include CrSerializer(TYPE)` to use the RequestBody converter." unless converter[:type].resolve.class.has_method?("from_json") %}
              {% elsif converter[:converter].stringify == "FormData" %}
                {% raise "#{converter[:type]} must implement a `self.from_form_data(form_data : HTTP::Params) : self` method to use the FormData converter." unless converter[:type].resolve.class.has_method?("from_form_data") %}
              {% end %}
            {% elsif converter %}
              {% raise "#{klass.name}.#{m.name} ParamConverter annotation is missing a required field.  Must specifiy `param`, `type`, and `converter`." %}
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

          # Set and normalize the prefix if one exists
          {% prefix = class_ann && class_ann[:prefix] ? parent_prefix + (class_ann[:prefix].starts_with?('/') ? class_ann[:prefix] : "/" + class_ann[:prefix]) : parent_prefix %}

          # Normalize the path
          {% path = (route_def[:path].starts_with?('/') ? route_def[:path] : "/" + route_def[:path]) %}

          # Build out full path
          {% full_path = "/" + method + prefix + path %}

          # Get array of path/query params for error handling
          {% route_params = (prefix + path).split('/').select { |p| p =~ (/:(\w+)/) }.map { |p| p.tr("(:)", "") } %}
          {% query_params = route_def[:query] ? route_def[:query] : {} of String => Regex? %}

          {% action_params = m.args.map(&.name.stringify) %}

          {% for p in (query_params.keys + route_params + ({"POST", "PUT"}.includes?(method) ? ["body"] : [] of String)) %}
            {% raise "'#{p.id}' is defined in #{klass.name}##{m.name} path/query parameters but is missing from action arguments." if !(action_params.includes?(p.gsub(/_id$/, "")) || action_params.includes?(p)) %}
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
            {% raise "'#{arg.name}' is defined in #{klass.name}##{m.name} action arguments but is missing from path/query parameters." unless found %}
          {% end %}

          {% constraints = route_def[:constraints] %}
          {% arg_types = m.args.map(&.restriction) %}

          {% groups = view_ann && view_ann[:groups] ? view_ann[:groups] : ["default"] %}
          {% renderer = view_ann && view_ann[:renderer] ? view_ann[:renderer] : "Athena::Routing::Renderers::JSONRenderer".id %}

          @routes.add {{full_path}}, 
            Route(Proc({{arg_types.splat}}, {{m.return_type.id == Nil.id ? Noop : m.return_type}}), {{arg_types.splat}}).new {{full_path}}, {{klass.id}}, ->%instance{c_idx}.{{m.name.id}}({{arg_types.splat}})
        {% end %}
        {{debug}}
      {% end %}
  end

  def resolve(request : HTTP::Request) : ART::Action
    route = @routes.find "/#{request.method}#{request.path}"

    action = route.found? ? route.payload.not_nil! : raise ART::Exceptions::NotFound.new "No route found for '#{request.method} #{request.path}'"

    action
  end
end
