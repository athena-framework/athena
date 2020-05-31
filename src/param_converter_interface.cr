abstract struct Athena::Routing::ParamConverterInterface
  TAG = "athena.param_converter"

  abstract struct ConfigurationInterface
    # The name of the argument the converter should be applied to.
    getter name : String

    # The converter class that should be used to convert the argument.
    getter converter : ART::ParamConverterInterface.class

    def initialize(@name : String, @converter : ART::ParamConverterInterface.class); end
  end

  struct Configuration < ConfigurationInterface; end

  def apply(request : HTTP::Request, configuration : Configuration) : Nil
    {% if @type < ART::ParamConverterInterface %}
      {% @type.raise "abstract `def Athena::Routing::ParamConverterInterface#apply(request : HTTP::Request, configuration : Configuration)` must be implemented by #{@type}" %}
    {% end %}
  end

  def apply(request : HTTP::Request, configuration) : Nil; end

  private macro configuration(*args)
    struct Configuration < ConfigurationInterface
      {% for arg in args %}
        getter {{arg}}
      {% end %}

      def initialize(
        {% for arg in args %}
          @{{arg}},
        {% end %}
        name : String,
        converter : ART::ParamConverterInterface.class
      )
        super name, converter
      end
    end
  end
end
