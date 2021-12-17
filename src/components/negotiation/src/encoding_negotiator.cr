require "./abstract_negotiator"

# A `ANG::AbstractNegotiator` implementation to negotiate `ANG::AcceptEncoding` headers.
class Athena::Negotiation::EncodingNegotiator < Athena::Negotiation::AbstractNegotiator(Athena::Negotiation::AcceptEncoding)
end
