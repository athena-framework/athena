struct DefaultController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "defaults")]
  def cors_defaults : String
    "default"
  end

  @[Athena::Routing::Post(path: "defaults")]
  def cors_defaults_post(body : String?) : String
    "default_post"
  end
end

@[Athena::Routing::ControllerOptions(cors: "class_overload")]
abstract struct OverloadController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "class_overload")]
  def cors_class_overload : String
    "class_overload"
  end

  @[Athena::Routing::Get(path: "action_overload", cors: "action_overload")]
  def cors_action_overload : String
    "action_overload"
  end

  @[Athena::Routing::Get(path: "disable_overload", cors: false)]
  def cors_disable_overload : String
    "disable_overload"
  end
end

struct InheritenceController < OverloadController
  @[Athena::Routing::Get(path: "inheritence")]
  def inheritence : String
    "inheritence"
  end

  @[Athena::Routing::Get(path: "inheritence_overload", cors: false)]
  def inheritence_overload : String
    "inheritence_overload"
  end
end
