# A token provider implementation that provides the JWT as a static value from the constructor.
struct Athena::Mercure::TokenProvider::Static
  include Athena::Mercure::TokenProvider::Interface

  def initialize(@token : String); end

  # :inherit:
  def jwt : String
    @token
  end
end
