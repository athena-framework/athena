# Determines whether an object should be cascaded.
#
# If cascading is enabled, the validator will also validate embedded objects.
enum Athena::Validator::Metadata::CascadingStrategy
  None
  Cascade
end
