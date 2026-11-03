# Returns the roles reachable from given roles, following a hierarchy of roles.
module Athena::Security::Role::HierarchyInterface
  # Returns the provided *roles*, along with the roles reachable from them.
  abstract def reachable_role_names(roles : Array(String)) : Array(String)
end
