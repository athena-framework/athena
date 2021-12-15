# Utility type for working with property paths.
module Athena::Validator::PropertyPath
  # Appends the provided *sub_path* to the provided *base_path* based on the following rules:
  #
  # * If the base path is empty, the sub path is returned as is.
  # * If the base path is not empty, and the sub path starts with an `[`,
  # the concatenation of the two paths is returned.
  # * If the base path is not empty, and the sub path does not start with an `[`,
  # the concatenation of the two paths is returned, separated by a `.`.
  #
  # ```
  # AVD::PropertyPath.append "", "sub_path"          # => "sub_path"
  # AVD::PropertyPath.append "base_path", "[0]"      # => "base_path[0]"
  # AVD::PropertyPath.append "base_path", "sub_path" # => "base_path.sub_path"
  # ```
  def self.append(base_path : String, sub_path : String) : String
    return base_path if sub_path.blank?

    return "#{base_path}#{sub_path}" if sub_path.starts_with? '['

    !base_path.blank? ? "#{base_path}.#{sub_path}" : sub_path
  end
end
