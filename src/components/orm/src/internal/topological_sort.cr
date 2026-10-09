# :nodoc:
#
# Implements topological sorting using depth-first search.
# Orders nodes such that for every edge A->B, B appears before A in the result.
#
# This algorithm has linear time complexity O(V + E) where V is the number
# of nodes and E is the number of edges.
class Athena::ORM::Internal::TopologicalSort
  private enum State
    NotVisited
    InProgress
    Visited
  end

  # Nodes indexed by object_id
  @nodes = Set(AORM::Entity).new.compare_by_identity

  # DFS state for each node
  @states = Hash(AORM::Entity, State).new.compare_by_identity

  # Edges: first key is source object_id, second key is destination object_id,
  # value indicates whether the edge is optional (can be ignored to break cycles)
  @edges = Hash(AORM::Entity, Hash(AORM::Entity, Bool)).new.compare_by_identity

  # Result built during DFS
  @sort_result = Array(AORM::Entity).new

  def add_node(node : AORM::Entity) : Nil
    @nodes << node
    @states[node] = State::NotVisited
    @edges[node] = Hash(AORM::Entity, Bool).new
  end

  def has_node?(node : AORM::Entity) : Bool
    @nodes.includes?(node)
  end

  # Adds an edge from one node to another.
  # The `optional` flag indicates whether this edge can be ignored to break cycles.
  def add_edge(from : AORM::Entity, to : AORM::Entity, optional : Bool) : Nil
    # Keep existing non-optional edge
    if @edges[from][to]? == false
      return
    end

    @edges[from][to] = optional
  end

  # Returns nodes in topological order.
  # For edge A->B, B appears before A in the result.
  def sort : Array(AORM::Entity)
    @nodes.each do |entity|
      if @states[entity].not_visited?
        visit(entity)
      end
    end

    @sort_result
  end

  private def visit(entity : AORM::Entity) : Nil
    if @states[entity].in_progress?
      # Found a cycle
      raise CycleDetectedException.new(entity)
    end

    if @states[entity].visited?
      # Already processed this node and its descendants
      return
    end

    @states[entity] = State::InProgress

    # Visit all adjacent nodes
    @edges[entity].each do |adjacent_id, optional|
      visit(adjacent_id)
    rescue ex : CycleDetectedException
      if ex.cycle_collected?
        # Complete cycle found downstream, nothing we can do
        raise ex
      end

      if optional
        # This edge is part of a cycle but is optional - break the cycle here
        next
      end

      # Cannot break cycle at this edge, backtrack
      @states[entity] = State::NotVisited
      ex.add_to_cycle(entity)
      raise ex
    end

    @states[entity] = State::Visited
    @sort_result << entity
  end
end
