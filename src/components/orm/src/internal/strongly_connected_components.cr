# :nodoc:
#
# Implements Tarjan's algorithm to find strongly connected components (SCC)
# in a directed graph. This algorithm has a linear running time based on
# nodes (V) and edges (E), resulting in a computational complexity of O(V + E).
#
# See https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
# for an explanation and the meaning of the DFS and lowlink numbers.
class Athena::ORM::Internal::StronglyConnectedComponents
  private enum State
    NotVisited
    InProgress
    Visited
  end

  # Nodes in the graph
  @nodes = Set(AORM::Entity).new.compare_by_identity

  # DFS state for each node
  @states = Hash(AORM::Entity, State).new.compare_by_identity

  # Edges: source -> set of destination nodes
  @edges = Hash(AORM::Entity, Set(AORM::Entity)).new.compare_by_identity

  # DFS numbers
  @dfs = Hash(AORM::Entity, Int32).new.compare_by_identity

  # lowlink numbers
  @lowlink = Hash(AORM::Entity, Int32).new.compare_by_identity

  @maxdfs : Int32 = 0

  # Maps each node to the representative node of its SCC
  @representing_nodes = Hash(AORM::Entity, AORM::Entity).new.compare_by_identity

  # Stack of nodes visited in the current DFS traversal
  @stack = Array(AORM::Entity).new

  def add_node(node : AORM::Entity) : Nil
    @nodes << node
    @states[node] = State::NotVisited
    @edges[node] = Set(AORM::Entity).new.compare_by_identity
  end

  def has_node?(node : AORM::Entity) : Bool
    @nodes.includes?(node)
  end

  def add_edge(from : AORM::Entity, to : AORM::Entity) : Nil
    @edges[from] << to
  end

  def find_strongly_connected_components : Nil
    @nodes.each do |node|
      if @states[node].not_visited?
        tarjan(node)
      end
    end
  end

  private def tarjan(node : AORM::Entity) : Nil
    @dfs[node] = @lowlink[node] = @maxdfs
    @maxdfs += 1
    @states[node] = State::InProgress
    @stack.push(node)

    @edges[node].each do |adjacent|
      if @states[adjacent].not_visited?
        tarjan(adjacent)
        @lowlink[node] = Math.min(@lowlink[node], @lowlink[adjacent])
      elsif @states[adjacent].in_progress?
        @lowlink[node] = Math.min(@lowlink[node], @dfs[adjacent])
      end
    end

    lowlink = @lowlink[node]
    if lowlink == @dfs[node]
      representing_node : AORM::Entity? = nil
      loop do
        unwind_node = @stack.pop

        representing_node ||= unwind_node

        @representing_nodes[unwind_node] = representing_node
        @states[unwind_node] = State::Visited
        break if unwind_node.same?(node)
      end
    end
  end

  def node_representing_strongly_connected_component(node : AORM::Entity) : AORM::Entity
    @representing_nodes[node]? || raise ArgumentError.new("unknown node")
  end
end
