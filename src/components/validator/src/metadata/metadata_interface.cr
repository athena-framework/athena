module Athena::Validator::Metadata::MetadataInterface
  # Returns the `AVD::Metadata::CascadingStrategy` for `self`.
  abstract def cascading_strategy : AVD::Metadata::CascadingStrategy

  abstract def constraints : Array(AVD::Constraint)

  # Returns an array of all constraints in the provided *group*.
  abstract def find_constraints(group : String) : Array(AVD::Constraint)
end
