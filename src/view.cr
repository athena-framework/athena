# :nodoc:
module Athena::Routing::ViewBase
end

# :nodoc:
struct Athena::Routing::View(T)
  include Athena::Routing::ViewBase

  getter data : T

  def initialize(@data : T); end
end
