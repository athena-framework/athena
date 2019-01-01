class Athena::ClassController
  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE, exclude: ["posts"])]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end

struct Athena::StructController
  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE, exclude: ["posts"])]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end

class CallbackController < Athena::ClassController
  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE)]
  def self.after_all(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-ALL-ROUTES", "true"
  end

  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE, only: ["users"])]
  def self.after_users(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-USER-ROUTE", "true"
  end

  @[Athena::Callback(event: CallbackEvents::ON_REQUEST, exclude: ["posts"])]
  def self.before_except_posts(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-REQUEST-NOT-POSTS-ROUTE", "true"
  end

  @[Athena::Get(path: "/callback/users")]
  def self.users : String
    "users"
  end

  @[Athena::Get(path: "/callback/all")]
  def self.all : Int32
    123
  end

  @[Athena::Get(path: "/callback/posts")]
  def self.posts : String
    "posts"
  end
end

class OtherCallbackController < Athena::ClassController
  @[Athena::Get(path: "/callback/other")]
  def self.other : String
    "other"
  end
end
