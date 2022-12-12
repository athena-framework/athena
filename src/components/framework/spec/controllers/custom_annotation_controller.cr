require "../spec_helper"

ACF.configuration_annotation SpecAnnotation
ACF.configuration_annotation CustomAnn, id : Int32

@[ADI::Register]
struct CustomAnnotationListener
  include AED::EventListenerInterface

  @[AEDA::AsEventListener]
  def on_response(event : ATH::Events::Response) : Nil
    return unless action = event.request.action?

    ann_configs = action.annotation_configurations

    if ann_configs.has?(SpecAnnotation)
      event.response.headers["ANNOTATION"] = "true"
    end

    if custom_ann = ann_configs[CustomAnn]?
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
end
