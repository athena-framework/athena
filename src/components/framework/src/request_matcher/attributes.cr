# Checks if all specified `ATH::Request#attributes` match the provided patterns.
struct Athena::Framework::RequestMatcher::Attributes
  include Interface

  def initialize(@regexes : Hash(String, Regex)); end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    @regexes.each do |key, regex|
      attribute = request.attributes.get key
      return false unless attribute.is_a? String
      return false unless attribute.matches? regex
    end

    true
  end
end
