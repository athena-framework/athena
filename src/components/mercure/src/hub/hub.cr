require "./interface"

# Default implementation of [AMC::Hub::Interface][].
class Athena::Mercure::Hub
  include Athena::Mercure::Hub::Interface

  # :inherit:
  getter token_provider : AMC::TokenProvider::Interface

  # :inherit:
  getter token_factory : AMC::TokenFactory::Interface?

  @uri : URI
  @public_url : String?
  @http_client : HTTP::Client

  def initialize(
    url : String,
    @token_provider : AMC::TokenProvider::Interface,
    @token_factory : AMC::TokenFactory::Interface? = nil,
    @public_url : String? = nil,
    http_client : HTTP::Client? = nil,
  )
    @uri = URI.parse url
    @http_client = http_client || HTTP::Client.new @uri
  end

  # :inherit:
  def url : String
    @uri.to_s
  end

  # :inherit:
  def public_url : String
    @public_url || @uri.to_s
  end

  # :inherit:
  def publish(update : AMC::Update) : String
    @http_client.post(
      @uri.path,
      headers: HTTP::Headers{"authorization" => "Bearer #{@token_provider.jwt}"},
      form: URI::Params.build { |form| self.encode form, update }
    ).body
  rescue ex : ::Exception
    raise AMC::Exception::Runtime.new "Failed to send an update.", cause: ex
  end

  private def encode(form : URI::Params::Builder, update : AMC::Update) : Nil
    form.add "topic", update.topics
    form.add "data", update.data

    if update.private?
      form.add "private", "on"
    end

    if id = update.id
      form.add "id", id
    end

    if type = update.type
      form.add "type", type
    end

    if retry = update.retry
      form.add "retry", retry.to_s
    end
  end
end
