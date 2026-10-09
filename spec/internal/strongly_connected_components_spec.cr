require "../spec_helper"

@[AORMA::Entity]
class TestEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32 = 0
end

describe Athena::ORM::Internal::StronglyConnectedComponents do
  describe "#add_node / #has_node?" do
    it "tracks added nodes" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new

      node = TestEntity.allocate
      scc.has_node?(node).should be_false

      scc.add_node(node)
      scc.has_node?(node).should be_true
    end

    it "distinguishes nodes by identity" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new

      node1 = TestEntity.allocate
      node2 = TestEntity.allocate

      scc.add_node(node1)

      scc.has_node?(node1).should be_true
      scc.has_node?(node2).should be_false
    end
  end

  describe "#node_representing_strongly_connected_component" do
    it "raises for unknown node" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      node = TestEntity.allocate

      expect_raises(ArgumentError, "unknown node") do
        scc.node_representing_strongly_connected_component(node)
      end
    end
  end

  describe "#find_strongly_connected_components" do
    it "handles a single node (its own SCC)" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      node = TestEntity.allocate

      scc.add_node(node)
      scc.find_strongly_connected_components

      scc.node_representing_strongly_connected_component(node).same?(node).should be_true
    end

    it "handles disconnected nodes (each is its own SCC)" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      node1 = TestEntity.allocate
      node2 = TestEntity.allocate
      node3 = TestEntity.allocate

      scc.add_node(node1)
      scc.add_node(node2)
      scc.add_node(node3)
      scc.find_strongly_connected_components

      rep1 = scc.node_representing_strongly_connected_component(node1)
      rep2 = scc.node_representing_strongly_connected_component(node2)
      rep3 = scc.node_representing_strongly_connected_component(node3)

      # Each node is its own representative
      rep1.same?(node1).should be_true
      rep2.same?(node2).should be_true
      rep3.same?(node3).should be_true
    end

    it "handles DAG with no cycles (each node is its own SCC)" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #   A -> B -> C
      node_a = TestEntity.allocate
      node_b = TestEntity.allocate
      node_c = TestEntity.allocate

      scc.add_node(node_a)
      scc.add_node(node_b)
      scc.add_node(node_c)
      scc.add_edge(node_a, node_b)
      scc.add_edge(node_b, node_c)
      scc.find_strongly_connected_components

      rep_a = scc.node_representing_strongly_connected_component(node_a)
      rep_b = scc.node_representing_strongly_connected_component(node_b)
      rep_c = scc.node_representing_strongly_connected_component(node_c)

      # In a DAG, each node is its own SCC
      rep_a.same?(node_a).should be_true
      rep_b.same?(node_b).should be_true
      rep_c.same?(node_c).should be_true
    end

    it "handles simple two-node cycle" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #   A <-> B
      node_a = TestEntity.allocate
      node_b = TestEntity.allocate

      scc.add_node(node_a)
      scc.add_node(node_b)
      scc.add_edge(node_a, node_b)
      scc.add_edge(node_b, node_a)
      scc.find_strongly_connected_components

      rep_a = scc.node_representing_strongly_connected_component(node_a)
      rep_b = scc.node_representing_strongly_connected_component(node_b)

      # Both should have the same representative (same SCC)
      rep_a.same?(rep_b).should be_true
    end

    it "handles three-node cycle" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #   A -> B -> C -> A
      node_a = TestEntity.allocate
      node_b = TestEntity.allocate
      node_c = TestEntity.allocate

      scc.add_node(node_a)
      scc.add_node(node_b)
      scc.add_node(node_c)
      scc.add_edge(node_a, node_b)
      scc.add_edge(node_b, node_c)
      scc.add_edge(node_c, node_a)
      scc.find_strongly_connected_components

      rep_a = scc.node_representing_strongly_connected_component(node_a)
      rep_b = scc.node_representing_strongly_connected_component(node_b)
      rep_c = scc.node_representing_strongly_connected_component(node_c)

      # All three should have the same representative
      rep_a.same?(rep_b).should be_true
      rep_b.same?(rep_c).should be_true
    end

    it "handles graph with multiple SCCs" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #   SCC1: A <-> B
      #   SCC2: C <-> D
      #   Edge: B -> C (connects SCC1 to SCC2)
      node_a = TestEntity.allocate
      node_b = TestEntity.allocate
      node_c = TestEntity.allocate
      node_d = TestEntity.allocate

      scc.add_node(node_a)
      scc.add_node(node_b)
      scc.add_node(node_c)
      scc.add_node(node_d)

      # SCC1: A <-> B
      scc.add_edge(node_a, node_b)
      scc.add_edge(node_b, node_a)

      # SCC2: C <-> D
      scc.add_edge(node_c, node_d)
      scc.add_edge(node_d, node_c)

      # Connect SCCs
      scc.add_edge(node_b, node_c)

      scc.find_strongly_connected_components

      rep_a = scc.node_representing_strongly_connected_component(node_a)
      rep_b = scc.node_representing_strongly_connected_component(node_b)
      rep_c = scc.node_representing_strongly_connected_component(node_c)
      rep_d = scc.node_representing_strongly_connected_component(node_d)

      # A and B should be in the same SCC
      rep_a.same?(rep_b).should be_true

      # C and D should be in the same SCC
      rep_c.same?(rep_d).should be_true

      # But SCC1 and SCC2 should be different
      rep_a.same?(rep_c).should be_false
    end

    it "handles self-loop" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #   A -> A
      node = TestEntity.allocate

      scc.add_node(node)
      scc.add_edge(node, node)
      scc.find_strongly_connected_components

      scc.node_representing_strongly_connected_component(node).same?(node).should be_true
    end

    it "handles complex graph with nested cycles" do
      scc = Athena::ORM::Internal::StronglyConnectedComponents.new
      #       A -> B -> C
      #       ^        |
      #       |        v
      #       +-- E <- D
      #
      # All nodes form one SCC
      node_a = TestEntity.allocate
      node_b = TestEntity.allocate
      node_c = TestEntity.allocate
      node_d = TestEntity.allocate
      node_e = TestEntity.allocate

      scc.add_node(node_a)
      scc.add_node(node_b)
      scc.add_node(node_c)
      scc.add_node(node_d)
      scc.add_node(node_e)

      scc.add_edge(node_a, node_b)
      scc.add_edge(node_b, node_c)
      scc.add_edge(node_c, node_d)
      scc.add_edge(node_d, node_e)
      scc.add_edge(node_e, node_a)

      scc.find_strongly_connected_components

      rep_a = scc.node_representing_strongly_connected_component(node_a)
      rep_b = scc.node_representing_strongly_connected_component(node_b)
      rep_c = scc.node_representing_strongly_connected_component(node_c)
      rep_d = scc.node_representing_strongly_connected_component(node_d)
      rep_e = scc.node_representing_strongly_connected_component(node_e)

      # All nodes should be in the same SCC
      rep_a.same?(rep_b).should be_true
      rep_b.same?(rep_c).should be_true
      rep_c.same?(rep_d).should be_true
      rep_d.same?(rep_e).should be_true
    end
  end
end
