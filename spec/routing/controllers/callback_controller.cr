abstract struct Athena::Routing::Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse, exclude: ["posts"])]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", Time.utc.to_unix.to_s
  end
end

struct CallbackController < Athena::Routing::Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def self.after_all(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-ALL-ROUTES", "true"
  end

  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse, only: ["users"])]
  def self.after_users(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-USER-ROUTE", "true"
  end

  @[Athena::Routing::Callback(event: CallbackEvents::OnRequest, exclude: ["posts"])]
  def self.before_except_posts(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-REQUEST-NOT-POSTS-ROUTE", "true"
  end

  @[Athena::Routing::Get(path: "/callback/users")]
  def users : String
    "users"
  end

  @[Athena::Routing::Get(path: "/callback/all")]
  def all : Int32
    123
  end

  @[Athena::Routing::Get(path: "/callback/posts")]
  def posts : String
    "posts"
  end
end

struct OtherCallbackController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "/callback/other")]
  def other : String
    "other"
  end
end

# Nested to test callback inheritence

abstract struct ZestedCallbackController < Athena::Routing::Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def self.parent_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-PARENT", Time.utc.to_unix.to_s
    sleep 1
  end

  @[Athena::Routing::Get(path: "/callback/nested/parent")]
  def parent : String
    "parent"
  end
end

abstract struct AestedCallback2Controller < ZestedCallbackController
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def self.child1_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-CHILD1", Time.utc.to_unix.to_s
    sleep 1
  end

  @[Athena::Routing::Get(path: "/callback/nested/child")]
  def parent : String
    "child"
  end
end

struct NestedCallback3Controller < AestedCallback2Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def self.child2_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-CHILD2", Time.utc.to_unix.to_s
    sleep 1
  end

  @[Athena::Routing::Get(path: "/callback/nested/child2")]
  def child : String
    "child2"
  end
end

struct NestedCallback4Controller < ZestedCallbackController
  @[Athena::Routing::Get(path: "/callback/nested/child3")]
  def child : String
    "child3"
  end
end
