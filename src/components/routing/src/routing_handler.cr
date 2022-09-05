# Provides basic routing functionality to an [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html).
#
# This type works as both a [HTTP::Handler](https://crystal-lang.org/api/HTTP/Handler.html) and
# an `ART::RouteCollection` that accepts a block that will handle that particular route.
#
# ```
# handler = ART::RoutingHandler.new
#
# # The `methods` property can be used to limit the route to a particular HTTP method.
# handler.add "new_article", ART::Route.new("/article", methods: "post") do |ctx|
#   pp ctx.request.body.try &.gets_to_end
# end
#
# # The match parameters from the route are passed to the callback as a `Hash(String, String?)`.
# handler.add "article", ART::Route.new("/article/{id<\\d+>}", methods: "get") do |ctx, params|
#   pp params # => {"_route" => "article", "id" => "10"}
# end
#
# # Call the `#compile` method when providing the handler to the handler array.
# server = HTTP::Server.new([
#   handler.compile,
# ])
#
# address = server.bind_tcp 8080
# puts "Listening on http://#{address}"
# server.listen
# ```
#
# NOTE: This handler should be the last one, as it is terminal.
class Athena::Routing::RoutingHandler
  include HTTP::Handler

  @handlers : Hash(String, Proc(HTTP::Server::Context, Hash(String, String?), Nil)) = {} of String => HTTP::Server::Context, Hash(String, String?) -> Nil

  # :nodoc:
  forward_missing_to @collection

  @collection : ART::RouteCollection

  def initialize(
    matcher : ART::Matcher::URLMatcherInterface? = nil,
    @collection : ART::RouteCollection = ART::RouteCollection.new
  )
    @matcher = matcher || ART::Matcher::URLMatcher.new ART::RequestContext.new
  end

  # :inherit:
  def call(context)
    request : ART::Request

    {% if @top_level.has_constant?("Athena") && Athena.has_constant?("Framework") && Athena::Framework.has_constant?("Request") %}
      request = ATH::Request.new context.request
    {% else %}
      request = context.request
    {% end %}

    @matcher.context.apply request

    begin
      parameters = if @matcher.is_a? ART::Matcher::RequestMatcherInterface
                     @matcher.match request
                   else
                     @matcher.match request.path
                   end
    rescue ex : ART::Exception::ResourceNotFound
      return context.response.respond_with_status(:not_found)
    rescue ex : ART::Exception::MethodNotAllowed
      return context.response.respond_with_status(:method_not_allowed)
    end

    @handlers[parameters["_route"]].call context, parameters
  end

  # :nodoc:
  def add(collection : ART::RouteCollection) : NoReturn
    raise ArgumentError.new "Cannot add an existing collection to a routing handler."
  end

  # Adds the provided *route* with the provided *name* to this collection, optionally with the provided *priority*.
  # The passed *block* will be called when a request matching this route is encountered.
  def add(name : String, route : ART::Route, priority : Int32 = 0, &block : HTTP::Server::Context, Hash(String, String?) -> Nil) : Nil
    @handlers[name] = block
    @collection.add name, route, priority
  end

  # Helper method that calls `ART.compile` with the internal `ART::RouteCollection`,
  # and returns `self` to make setting up the routes easier.
  #
  # ```
  # handler = ART::RoutingHandler.new
  #
  # # Register routes
  #
  # server = HTTP::Server.new([
  #   handler.compile,
  # ])
  # ```
  def compile : self
    ART.compile @collection

    self
  end
end
