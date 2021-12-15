require "./abstract_negotiator"

# A `ANG::AbstractNegotiator` implementation to negotiate `ANG::AcceptCharset` headers.
class Athena::Negotiation::CharsetNegotiator < Athena::Negotiation::AbstractNegotiator(Athena::Negotiation::AcceptCharset)
end
