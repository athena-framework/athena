require "./abstract_negotiator"

# A `ANG::AbstractNegotiator` implementation to negotiate `ANG::AcceptLanguage` headers.
class Athena::Negotiation::LanguageNegotiator < Athena::Negotiation::AbstractNegotiator(Athena::Negotiation::AcceptLanguage)
  protected def match(accept : ANG::AcceptLanguage, priority : ANG::AcceptLanguage, index : Int32) : ANG::AcceptMatch?
    accept_base = accept.language
    priority_base = priority.language

    accept_sub = accept.region
    priority_sub = priority.region

    base_equal = accept_base.downcase == priority_base.downcase
    sub_equal = accept_sub.try &.downcase == priority_sub.try &.downcase

    if (accept_base == "*" || base_equal) && (accept_sub.nil? || sub_equal)
      score = 10 * (base_equal ? 1 : 0) + (sub_equal ? 1 : 0)

      return ANG::AcceptMatch.new accept.quality * priority.quality, score, index
    end

    nil
  end
end
