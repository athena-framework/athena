# Like `ASEC::Authorization::Voter::Role`, but also grants the roles reachable from the roles of the token via an `ASEC::Role::HierarchyInterface`.
class Athena::Security::Authorization::Voter::RoleHierarchy < Athena::Security::Authorization::Voter::Role
  def initialize(@role_hierarchy : ASEC::Role::HierarchyInterface, prefix : String = "ROLE_")
    super prefix
  end

  protected def extract_roles(token : ASEC::Authentication::Token::Interface) : Array(String)
    @role_hierarchy.reachable_role_names token.role_names
  end
end
