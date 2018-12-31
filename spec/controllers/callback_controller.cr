class CallbackController < Athena::ClassController
  @[Athena::Trigger(event: Listener::ON_RESPONSE)]
  def self.after_all(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-ALL-ROUTES", "true"
  end

  @[Athena::Trigger(event: Listener::ON_RESPONSE, only_actions: ["users"])]
  def self.after_users(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-USER-ROUTE", "true"
  end

  @[Athena::Trigger(event: Listener::ON_REQUEST, exclude_actions: ["posts"])]
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
