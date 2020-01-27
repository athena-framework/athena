module Athena::Routing::ViewBase
end

struct Athena::Routing::View(T)
  include Athena::Routing::ViewBase

  getter data : T

  def initialize(@data : T); end
end
