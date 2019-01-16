class Athena::Routing::ClassController
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse, exclude: ["posts"])]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end

struct Athena::Routing::StructController
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse, exclude: ["posts"])]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end

class CallbackController < Athena::Routing::ClassController
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
  def self.users : String
    "users"
  end

  @[Athena::Routing::Get(path: "/callback/all")]
  def self.all : Int32
    123
  end

  @[Athena::Routing::Get(path: "/callback/posts")]
  def self.posts : String
    "posts"
  end
end

class OtherCallbackController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "/callback/other")]
  def self.other : String
    "other"
  end
end
