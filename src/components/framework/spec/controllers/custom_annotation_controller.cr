require "../spec_helper"

ADI.configuration_annotation SpecAnnotation
ADI.configuration_annotation CustomAnn, id : Int32
ADI.configuration_annotation TopParameterAnn
ADI.configuration_annotation MyApp::NestedParameterAnn

@[ADI::Register]
struct CustomAnnotationListener
  def initialize(
    @annotation_resolver : ATH::AnnotationResolver,
  ); end

  @[AEDA::AsEventListener]
  def on_response(event : AHK::Events::Response) : Nil
    action_annotations = @annotation_resolver.action_annotations event.request

    if action_annotations.has?(SpecAnnotation)
      event.response.headers["ANNOTATION"] = "true"
    end

    if custom_ann = action_annotations[CustomAnn]?
      event.response.headers["ANNOTATION_VALUE"] = custom_ann.id.to_s
    end
  end
end

@[CustomAnn(1)]
class AnnotationController < ATH::Controller
  @[SpecAnnotation]
  get("/with-ann", return_type: Nil) { }
  get("/without-ann", return_type: Nil) { }

  @[CustomAnn(2)]
  get("/with-ann-override", return_type: Nil) { }

  @[ARTA::Get("/top-parameter-ann/{id}")]
  def top_parameter_ann(@[TopParameterAnn] id : Int32) : Nil
  end

  @[ARTA::Get("/nested-parameter-ann/{id}")]
  def nested_parameter_ann(@[MyApp::NestedParameterAnn] id : Int32) : Nil
  end
end
