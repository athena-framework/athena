# Adds `mercureAuthorization` cookies that were stored in the request attributes via `ABM::Authorization`.
@[ADI::Register]
struct Athena::MercureBundle::Listeners::SetCookie
  # :nodoc:
  def initialize; end

  @[AEDA::AsEventListener]
  def on_response(event : AHK::Events::Response) : Nil
    return unless cookies = event.request.attributes.get? "_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)

    event.request.attributes.remove "_mercure_authorization_cookies"

    cookies.each_value do |cookie|
      event.response.headers << cookie
    end
  end
end
