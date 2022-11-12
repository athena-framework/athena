require "./abstract_negotiator"

# A `ANG::AbstractNegotiator` implementation to negotiate `ANG::Accept` headers.
class Athena::Negotiation::Negotiator < Athena::Negotiation::AbstractNegotiator(Athena::Negotiation::Accept)
  # TODO: Make this method less complex.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  protected def match(accept : ANG::Accept, priority : ANG::Accept, index : Int32) : ANG::AcceptMatch?
    accept_type = accept.type
    priority_type = priority.type

    accept_sub_type = accept.sub_type
    priority_sub_type = priority.sub_type

    intersection = accept.parameters.each_with_object({} of String => String) do |(k, v), params|
      priority.parameters.tap do |pp|
        params[k] = v if pp.has_key?(k) && pp[k] == v
      end
    end

    type_equals = accept_type.downcase == priority_type.downcase
    sub_type_equals = accept_sub_type.downcase == priority_sub_type.downcase

    if (
         (accept_type == "*" || type_equals) &&
         (accept_sub_type == "*" || sub_type_equals) &&
         intersection.size == accept.parameters.size
       )
      score = 100 * (type_equals ? 1 : 0) + 10 * (sub_type_equals ? 1 : 0) + intersection.size

      return ANG::AcceptMatch.new accept.quality * priority.quality, score, index
    end

    return nil if !accept_sub_type.includes?('+') || !priority_sub_type.includes?('+')

    accept_sub_type, accept_plus = self.split_sub_type accept_sub_type
    priority_sub_type, priority_plus = self.split_sub_type priority_sub_type

    if (
         !(accept_type == "*" || type_equals) ||
         !(accept_sub_type == "*" || priority_sub_type == "*" || accept_plus == "*" || priority_plus == "*")
       )
      return nil
    end

    sub_type_equals = accept_sub_type.downcase == priority_sub_type.downcase
    plus_equals = accept_plus.downcase == priority_plus.downcase

    if (
         (accept_sub_type == "*" || priority_sub_type == "*" || sub_type_equals) &&
         (accept_plus == "*" || priority_plus == '*' || plus_equals) &&
         intersection.size == accept.parameters.size
       )
      score = 100 * (type_equals ? 1 : 0) + 10 * (sub_type_equals ? 1 : 0) + (plus_equals ? 1 : 0) + intersection.size
      return ANG::AcceptMatch.new accept.quality * priority.quality, score, index
    end

    nil
  end

  private def split_sub_type(sub_type : String) : Array(String)
    return [sub_type, ""] unless sub_type.includes? '+'

    sub_type.split '+', limit: 2
  end
end
