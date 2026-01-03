@[ADI::Register]
# Allows resolving [custom annotations](/getting_started/configuration/#custom-annotations) defined on an `ATH::Controller` class or `ATH::Action` method, or one of its parameters.
class Athena::Framework::AnnotationResolver
  # :nodoc:
  ACTION_ANNOTATIONS = {} of String => ADI::AnnotationConfigurations

  # :nodoc:
  ACTION_PARAMETER_ANNOTATIONS = {} of String => Hash(String, ADI::AnnotationConfigurations)

  # Returns an [ADI::AnnotationConfigurations](/DependencyInjection/AnnotationConfigurations) instance representing the custom annotations applied on an `ATH::Controller` class or `ATH::Action` method.
  # An empty instance is returned if there are no custom annotations applied.
  def action_annotations(request : AHTTP::Request) : ADI::AnnotationConfigurations
    return ADI::AnnotationConfigurations.new unless controller = request.attributes.get? "_controller", String

    ACTION_ANNOTATIONS[controller]? || ADI::AnnotationConfigurations.new
  end

  # Returns an [ADI::AnnotationConfigurations](/DependencyInjection/AnnotationConfigurations) instance representing the custom annotations applied on an `ATH::Action` method parameter.
  # An empty instance is returned if there are no custom annotations applied.
  def action_parameter_annotations(request : AHTTP::Request, parameter_name : String) : ADI::AnnotationConfigurations
    return ADI::AnnotationConfigurations.new unless controller = request.attributes.get? "_controller", String

    ACTION_PARAMETER_ANNOTATIONS[controller]?.try(&.[parameter_name]?) || ADI::AnnotationConfigurations.new
  end
end
