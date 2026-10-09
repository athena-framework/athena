# :nodoc:
#
# Raised when a cycle is detected during topological sorting.
# Tracks the nodes forming the cycle for diagnostic purposes.
class Athena::ORM::Internal::TopologicalSort::CycleDetectedException < Athena::ORM::Exceptions::ORMException
  getter cycle : Array(AORM::Entity)
  getter? cycle_collected : Bool = false

  def initialize(@start_node : AORM::Entity)
    super("A cycle has been detected, so a topological sort is not possible. The cycle method provides the list of nodes that form the cycle.")
    @cycle = [@start_node]
  end

  def add_to_cycle(node : AORM::Entity) : Nil
    @cycle.unshift(node)

    if node.same?(@start_node)
      @cycle_collected = true
    end
  end
end
