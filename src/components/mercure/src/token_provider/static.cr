struct Athena::Mercure::TokenProvider::Static
  include Athena::Mercure::TokenProvider::Interface

  def initialize(@token : String); end

  def jwt : String
    @token
  end
end
