struct DefaultController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "defaults")]
  def self.cors_defaults : String
    "default"
  end

  @[Athena::Routing::Post(path: "defaults")]
  def self.cors_defaults_post : String
    "default_post"
  end
end

@[Athena::Routing::ControllerOptions(cors: "class_overload")]
struct OverloadController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "class_overload")]
  def self.cors_class_overload : String
    "class_overload"
  end

  @[Athena::Routing::Get(path: "action_overload", cors: "action_overload")]
  def self.cors_action_overload : String
    "action_overload"
  end

  @[Athena::Routing::Get(path: "disable_overload", cors: false)]
  def self.cors_disable_overload : String
    "disable_overload"
  end
end
