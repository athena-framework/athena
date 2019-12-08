class Athena::Routing::RouteResolver
  @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

  def initialize
    {% for klass, c_idx in Athena::Routing::Controller.all_subclasses.reject &.abstract? %}
        {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) } %}
        {% class_ann = klass.annotation(Athena::Routing::ControllerOptions) %}

        # Raise compile time exception if a route is defined as a class method.
        {% unless class_actions.empty? %}
          {% raise "Routes can only be defined as instance methods.  Did you mean '#{class_actions.first.name}' within #{klass.name}?" %}
        {% end %}

        {% parent_prefix = "" %}

        %instance{c_idx} = {{klass.id}}.new

        # Build out the routes
        {% for m, m_idx in methods %}
          {% raise "Route action return type must be set for '#{klass.name}##{m.name}'" if m.return_type.is_a? Nop %}

          {% param_converters = m.annotations(ParamConverter) %}

          {% for converter in param_converters %}
            # Ensure each converter implements required properties and `type` implements the required methods.
            {% if converter && converter[:arg] && converter[:converter] %}
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
          {% arg_types = m.args.map(&.restriction) %}

          # Build out params array
          %params{m_idx} = [] of ART::Parameters::Param

          {% for arg in m.args %}
            {% if arg.restriction.resolve == HTTP::Request %}
              %params{m_idx} << ART::Parameters::RequestParameter(HTTP::Request).new {{arg.name.stringify}}
            {% elsif qp = m.annotations(ART::QueryParam).find { |query_param| (name = query_param[:name]) ? name == arg.name.stringify : raise "QueryParam annotation on #{klass}##{m.name} is missing required field: 'name'." } %}
              %params{m_idx} << ART::Parameters::QueryParameter({{arg.restriction}}).new name: {{qp[:name]}}, converter: {{qp[:converter] ? "#{qp[:converter]}(#{arg.restriction}, Nil).new".id : nil}} {% if qp[:default] == nil %}, default: {{arg.default_value.is_a?(Nop) ? nil : arg.default_value}} {% end %}
            {% else %}
              {% ca = m.annotations(ART::ParamConverter).find { |pc| pc[:arg] == arg.name.stringify } %}

              %params{m_idx} << ART::Parameters::PathParameter({{arg.restriction}}).new name: {{arg.name.stringify}}, converter: {{ca && ca[:converter] ? "#{ca[:converter]}(#{arg.restriction}, #{ca[:pk_type] ? ca[:pk_type] : Nil}).new".id : nil}}, default: {{arg.default_value.is_a?(Nop) ? nil : arg.default_value}}
            {% end %}
          {% end %}

          # Add the route to the router
          @routes.add(
            {{full_path}},
            # TODO: Just do `Route(ReturnType, *Args)` once https://github.com/crystal-lang/crystal/issues/8520 is fixed.
            Route(Proc({{arg_types.splat}}{% if m.args.size > 0 %},{% end %}{{m.return_type}}), {{m.return_type}}, {{arg_types.splat}}).new(
              {{klass.id}},
              ->%instance{c_idx}.{{m.name.id}}{% if m.args.size > 0 %}({{arg_types.splat}}){% end %},
              %params{m_idx},
            ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
          )
        {% end %}
      {% end %}
  end

  def resolve(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::Action)
    route = @routes.find "/#{request.method}#{request.path}"

    raise ART::Exceptions::NotFound.new "No route found for '#{request.method} #{request.path}'" unless route.found?

    route
  end
end
