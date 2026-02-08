The `Athena::Routing` component provides a performant and robust HTTP based routing library/framework.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-routing:
    github: athena-framework/routing
    version: ~> 0.1.0
```

## Usage

This component is primarily intended to be used as a basis for a routing implementation for a framework, handling the majority of the heavy lifting.

The routing component supports various ways to control which routes are matched, including:

* Regex patterns
* [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header values
* HTTP method/scheme
* Request format/locale
* Dynamic callbacks

Using the routing component involves adding [ART::Route](/Routing/Route/) instances to an [ART::RouteCollection](/Routing/RouteCollection/).
The collection is then compiled via [ART.compile](</Routing/top_level/#Athena::Routing.compile(routes,*,route_provider)>).
From here, an [ART::Matcher::URLMatcherInterface](/Routing/Matcher/URLMatcherInterface/) or [ART::Matcher::RequestMatcherInterface](/Routing/Matcher/RequestMatcherInterface/) could then be used to determine which route matches a given path or [ART::Request](/Routing/Request/).

```crystal
# Create a new route collection and add a route with a single parameter to it.
routes = ART::RouteCollection.new
routes.add "blog_show", ART::Route.new "/blog/{slug}"

# Compile the routes.
ART.compile routes

# Represents the request in an agnostic data format.
# In practice this would be created from the current `ART::Request`.
context = ART::RequestContext.new

# Match a request by path.
matcher = ART::Matcher::URLMatcher.new context
matcher.match "/blog/foo-bar" # => ART::Parameters{"_route" => "blog_show", "slug" => "foo-bar"}
```

It is also possible to go the other way, generate a URL based on its name and set of parameters:

```crystal
# Generating routes based on route name and parameters is also possible.
generator = ART::Generator::URLGenerator.new context
generator.generate "blog_show", slug: "bar-baz", source: "Crystal" # => "/blog/bar-baz?source=Crystal"
```

### Simple Webapp

The Crystal stdlib provides [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html) as a very robust basis to a web application.
However it lacks a fairly critical feature: routing.
The Routing component provides [ART::RoutingHandler](/Routing/RoutingHandler/) which can be used to add basic routing functionality.
This can be a good choice for super simple web applications that do not need any additional frameworky features.

```crystal
handler = ART::RoutingHandler.new

# The `methods` property can be used to limit the route to a particular HTTP method.
handler.add "new_article", ART::Route.new("/article", methods: "post") do |ctx|
  pp ctx.request.body.try &.gets_to_end
end

# The match parameters from the route are passed to the callback as a `Hash(String, String?)`.
handler.add "article", ART::Route.new("/article/{id<\\d+>}", methods: "get") do |ctx, params|
  pp params # => {"_route" => "article", "id" => "10"}
end

# Call the `#compile` method when providing the handler to the handler array.
server = HTTP::Server.new([
  handler.compile,
])

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
```

## Learn More

* [Parameter Validation](/Routing/Route/#Athena::Routing::Route--parameter-validation)
* Route [Requirement](/Routing/Requirement/) helpers
* [Catch-all/Glob](/Routing/Route/#Athena::Routing::Route--slash-characters-in-route-parameters) routes
