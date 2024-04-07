module Athena::DependencyInjection
  # :nodoc:
  CUSTOM_ANNOTATIONS = [] of Nil

  # Registers a configuration annotation with the provided *name*.
  # Defines a configuration record with the provided *args*, if any, that represents the possible arguments that the annotation accepts.
  # May also be used with a block to add custom methods to the configuration record.
  #
  # ### Example
  #
  # ```
  # # Defines an annotation without any arguments.
  # ADI.configuration_annotation Secure
  #
  # # Defines annotation with a required and optional argument.
  # # The default value will be used if that key isn't supplied in the annotation.
  # ADI.configuration_annotation SomeAnn, id : Int32, debug : Bool = true
  #
  # # A block can be used to define custom methods on the configuration object.
  # ADI.configuration_annotation CustomAnn, first_name : String, last_name : String do
  #   def name : String
  #     "#{@first_name} #{@last_name}"
  #   end
  # end
  # ```
  #
  # NOTE: The logic to actually do the resolution of the annotations must be handled in the owning shard.
  # `Athena::DependencyInjection` only defines the common logic that each implementation can use.
  # See `ADI::AnnotationConfigurations` for more information.
  macro configuration_annotation(name, *args, &)
    annotation {{name.id}}; end

    # :nodoc:
    record {{name.id}}Configuration < ADI::AnnotationConfigurations::ConfigurationBase{% unless args.empty? %}, {{args.splat}}{% end %} do
      {{yield}}
    end

    {% CUSTOM_ANNOTATIONS << name %}
  end

  # Wraps a hash of configuration annotations applied to a given type, method, or instance variable.
  # Provides the logic to access each annotation's configuration in a type safe manner.
  #
  # Implementations using this type must define the logic to provide the annotation hash manually;
  # this would most likely just be something like:
  #
  # ```
  # # Define a hash to store the configurations.
  # {% custom_configurations = {} of Nil => Nil %}
  #
  # # Iterate over the stored annotation classes.
  # {% for ann_class in ADI::CUSTOM_ANNOTATIONS %}
  #    {% ann_class = ann_class.resolve %}
  #
  #    # Define an array to store the annotation configurations of this type.
  #    {% annotations = [] of Nil %}
  #
  #    # Iterate over each annotation of this type on the given type, method, or instance variable.
  #    {% for ann in type_method_instance_variable.annotations ann_class %}
  #      # Add a new instance of the annotations configuration to the array.
  #      # Add the annotation's positional arguments first, if any, then named arguments.
  #      {% annotations << "#{ann_class}Configuration.new(#{ann.args.empty? ? "".id : "#{ann.args.splat},".id}#{ann.named_args.double_splat})".id %}
  #    {% end %}
  #
  #    # Update the configuration hash with the annotation class and configuration objects, but only if there was at least one.
  #    {% custom_configurations[ann_class] = "(#{annotations} of ADI::AnnotationConfigurations::ConfigurationBase)".id unless annotations.empty? %}
  #  {% end %}
  #
  # # ...
  #
  # # Use the built hash to instantiate a new `ADI::AnnotationConfigurations` instance.
  # ADI::AnnotationConfigurations.new({{custom_configurations}} of ADI::AnnotationConfigurations::Classes => Array(ADI::AnnotationConfigurations::ConfigurationBase)),
  # ```
  #
  # TODO: Centralize the hash resolution logic once [this issue](https://github.com/crystal-lang/crystal/issues/8835) is resolved.
  struct AnnotationConfigurations
    # Base type of annotation configuration objects registered via `Athena::DependencyInjection.configuration_annotation`.
    abstract struct ConfigurationBase; end

    # :nodoc:
    #
    # Used to type the `#annotation_hash` when there are no user defined annotations.
    annotation Placeholder; end

    macro finished
      # A union representing the possible annotation classes that could be applied to a type, method, or instance variable.
      alias Classes = {{%(Union(#{ADI::CUSTOM_ANNOTATIONS.empty? ? "Placeholder.class".id : ADI::CUSTOM_ANNOTATIONS.map { |t| "#{t}.class".id }.splat})).id}}

      # The Hash type that will store the annotation configurations.
      alias AnnotationHash = Hash(ADI::AnnotationConfigurations::Classes, Array(ADI::AnnotationConfigurations::ConfigurationBase))

      def initialize(@annotation_hash : AnnotationHash = AnnotationHash.new); end

      {% for ann_class in ADI::CUSTOM_ANNOTATIONS %}
        # Returns the `{{ann_class}}` configuration instance for the provided *ann_class* at the provided *index*.
        #
        # Returns the last configuration instance by default.
        def [](ann_class : {{ann_class}}.class, index : Int32 = -1) : {{ann_class}}Configuration
          self.[]?(ann_class, index) || raise KeyError.new "No annotations of type '#{ann_class}' were found."
        end

        # Returns the `{{ann_class}}` configuration instance for the provided *ann_class* at the provided *index*,
        # or `nil` if no annotations of that type were found.
        #
        # Returns the last configuration instance by default.
        def []?(ann_class : {{ann_class}}.class, index : Int32 = -1) : {{ann_class}}Configuration?
          @annotation_hash[ann_class]?.try(&.[index]).as {{ann_class}}Configuration?
        end

        # Returns an array of `{{ann_class}}` configuration instances for the provided *ann_class*.
        def fetch_all(ann_class : {{ann_class}}.class) : Array(ADI::AnnotationConfigurations::ConfigurationBase)
          @annotation_hash[ann_class]? || Array(ADI::AnnotationConfigurations::ConfigurationBase).new
        end
      {% end %}

      # Returns `true` if there are annotations of the provided *ann_class*, otherwise `false`.
      def has?(ann_class : ADI::AnnotationConfigurations::Classes) : Bool
        @annotation_hash.has_key? ann_class
      end
    end
  end
end
