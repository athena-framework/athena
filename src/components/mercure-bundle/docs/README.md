The `Athena::MercureBundle` integrates the `Athena::Mercure` component into the Athena framework; abstracting away the setup down to just a couple configuration values.

## Installation

First, install the bundle by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-mercure_bundle:
    github: athena-framework/mercure-bundle
    version: ~> 0.1.0
```

Then, require it:
```crystal
require "athena-mercure_bundle"
```
This automatically registers the bundle with the framework.

Finally, configure it with at least one hub and required configuration:
```crystal
ADI.configure({
  mercure: {
    hubs: {
      default: {
        url:        ENV["MERCURE_URL"],
        jwt: {
          secret:    ENV["MERCURE_JWT_SECRET"],
          publish:   ["*"],
          subscribe: ["*"],
        },
      },
    },
  },
})
```
See the bundle [Schema](/MercureBundle/Schema) for the full set of possible configuration options.

If multiple hubs are configured, they may be injected using the hub name as a constructor parameter typed to [AMC::Hub::Interface](/Mercure/Hub/Interface/).
For example `some_hub : AMC::Hub::Interface` assuming the key used in the `hubs` named tuple was `some_hub`.

## Usage

The Mercure bundle brings [AMC::Hub](/Mercure/Hub/), [AMC::Authorization](/Mercure/Authorization/), and [AMC::Discovery](/Mercure/Discovery/) into the framework as injectable services, with event listeners that handle response headers and cookies automatically.

### Publishing

Inject [AMC::Hub::Interface](/Mercure/Hub/Interface/) to publish updates from a controller:

```crystal
@[ARTA::Route(path: "/broadcast")]
class BroadcastController < ATH::Controller
  def initialize(@hub : AMC::Hub::Interface); end

  @[ARTA::Post("/")]
  def broadcast : Nil
    @hub.publish AMC::Update.new(
      "https://example.com/books/1",
      {status: "OutOfStock"}.to_json
    )
  end
end
```

### Authorization

Inject [ABM::Authorization](/MercureBundle/Authorization/) to set the `mercureAuthorization` cookie for [private updates](/Mercure/#authorization).
The [SetCookie](/MercureBundle/Listeners/SetCookie/) listener automatically adds the cookie to the response — there is no need to modify the response directly:

```crystal
@[ARTA::Route(path: "/auth")]
class AuthController < ATH::Controller
  def initialize(@authorization : ABM::Authorization); end

  @[ARTA::Get("/subscribe")]
  def subscribe(request : AHTTP::Request) : Nil
    @authorization.set_cookie(
      request,
      subscribe: ["https://example.com/books/{id}"],
    )
  end
end
```

See [Authorization](/Mercure/#authorization) in the Mercure component docs for more on private updates and cookie-based auth.

### Discovery

Inject [ABM::Discovery](/MercureBundle/Discovery/) to add the Mercure hub `Link` header to a response.
The [AddLinkHeader](/MercureBundle/Listeners/AddLinkHeader/) listener handles adding the header — there is no need to modify the response directly:

```crystal
@[ARTA::Route(path: "/books")]
class BookController < ATH::Controller
  def initialize(@discovery : ABM::Discovery); end

  @[ARTA::Get("/{id}")]
  def show(request : AHTTP::Request, id : Int32) : {id: Int32, title : String}
    @discovery.add_link request

    {id: id, title: "Hello World!"}
  end
end
```

The response will include a `Link: <https://hub.example.com/.well-known/mercure>; rel="mercure"` header.
A client can then extract the hub URL to subscribe to updates for this resource:

```js
fetch('/books/1')
  .then(response => {
    const hubUrl = response.headers.get('Link').match(/<([^>]+)>;\s+rel=(?:mercure|"[^"]*mercure[^"]*")/)[1];

    const hub = new URL(hubUrl, window.origin);
    hub.searchParams.append('topic', 'https://example.com/books/{id}');

    const eventSource = new EventSource(hub);
    eventSource.onmessage = event => console.log(event.data);
  });
```

See [Discovery](/Mercure/#discovery) in the Mercure component docs for more on the discovery protocol.
