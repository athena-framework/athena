require "./interface"

# A token provider implementation that provides the JWT via the return value of a callback block.
struct Athena::Mercure::TokenProvider::Callable
  include Athena::Mercure::TokenProvider::Interface

  def self.new(&block : -> String) : self
    new block
  end

  def initialize(@callback : Proc(String)); end

  # :inherit:
  def jwt : String
    @callback.call
  end
end
