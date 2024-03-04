require "./interface"

struct Athena::Mercure::TokenProvider::Callable
  include Athena::Mercure::TokenProvider::Interface

  def self.new(&block : -> String) : self
    new block
  end

  def initialize(@callback : Proc(String)); end

  def jwt : String
    @callback.call
  end
end
