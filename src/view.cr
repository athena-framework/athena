# Parent type of a view just used for typing.
#
# See `ART::View`.
module Athena::Routing::ViewBase
end

# Currently just used as a container to hold a controller action's result.
#
# See `ART::Events::View` and `ART::Listeners::View`.
struct Athena::Routing::View(T)
  include Athena::Routing::ViewBase

  # The result of executing the associated controller action.
  getter data : T

  def initialize(@data : T); end
end
