# A hierarchy of roles, where a role is granted the roles below it, and in turn the roles below those.
#
# ```
# hierarchy = ASEC::Role::Hierarchy.new({
#   "ROLE_ADMIN"       => ["ROLE_USER"],
#   "ROLE_SUPER_ADMIN" => ["ROLE_ADMIN", "ROLE_BILLING"],
# })
#
# hierarchy.reachable_role_names ["ROLE_SUPER_ADMIN"] # => ["ROLE_SUPER_ADMIN", "ROLE_ADMIN", "ROLE_USER", "ROLE_BILLING"]
# ```
#
# A role may contain wildcards, a `*` preceded by `_` and followed by `_` or the end of the role.
# It then grants its roles to each role it matches, without being granted itself.
#
# ```
# hierarchy = ASEC::Role::Hierarchy.new({"ROLE_ADMIN_*" => ["ROLE_ADMIN"]})
#
# hierarchy.reachable_role_names ["ROLE_ADMIN_BLOG"] # => ["ROLE_ADMIN_BLOG", "ROLE_ADMIN"]
# ```
class Athena::Security::Role::Hierarchy
  include Athena::Security::Role::HierarchyInterface

  # Maps each role of the hierarchy to the roles it reaches.
  @map = Hash(String, Array(String)).new

  # The regex matching the roles each placeholder of the hierarchy stands for, keyed by placeholder.
  @role_placeholders_patterns = Hash(String, Regex).new

  def initialize(@hierarchy : Hash(String, Array(String)))
    self.build_role_map
  end

  # :inherit:
  def reachable_role_names(roles : Array(String)) : Array(String)
    reachable_roles = Set(String).new

    roles.each do |role|
      reachable_roles << role

      next unless map = @map[role]?

      reachable_roles.concat map
    end

    self.add_roles_matching_placeholders reachable_roles unless @role_placeholders_patterns.empty?

    reachable_roles.to_a
  end

  protected def build_role_map : Nil
    @map.clear
    @role_placeholders_patterns.clear

    @hierarchy.each do |main, roles|
      map = Set(String).new
      visited = [] of String
      additional_roles = roles.dup
      index = 0

      while role = additional_roles[index]?
        index += 1
        map << role

        next unless hierarchy_roles = @hierarchy[role]?

        visited << role
        map.concat hierarchy_roles
        additional_roles.concat hierarchy_roles - visited
      end

      @map[main] = map.to_a

      if main.includes?('*') && (pattern = self.placeholder_pattern main)
        @role_placeholders_patterns[main] = pattern
      end
    end
  end

  # Returns the placeholders of the hierarchy matched by at least one of the provided *roles*.
  protected def matching_placeholders(roles : Enumerable(String)) : Array(String)
    @role_placeholders_patterns.compact_map do |placeholder, pattern|
      placeholder if roles.any? &.matches?(pattern)
    end
  end

  # Adds the roles the matched placeholders stand for, and the ones those roles reach in turn.
  #
  # The placeholders themselves are never added, as they are patterns rather than roles.
  private def add_roles_matching_placeholders(reachable_roles : Set(String)) : Nil
    visited = [] of String

    until (placeholders = self.matching_placeholders(reachable_roles) - visited).empty?
      placeholders.each do |placeholder|
        visited << placeholder

        @map[placeholder]?.try { |roles| reachable_roles.concat roles }
      end
    end
  end

  # Returns the regex matching the roles the provided *role* stands for, or `nil` if it has no valid wildcard.
  private def placeholder_pattern(role : String) : Regex?
    count = 0
    pattern = Regex.escape(role).gsub(/(?<=_)\\\*(?=_|$)/) do
      count += 1
      ".*"
    end

    count > 0 ? Regex.new("\\A#{pattern}\\z") : nil
  end
end
