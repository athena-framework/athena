# :nodoc:
struct Athena::Negotiation::AcceptMatch
  include Comparable(self)

  getter quality : Float32
  getter score : Int32
  getter index : Int32

  def self.reduce(matches : Hash(Int32, self), match : self) : Hash(Int32, self)
    if !matches.has_key?(match.index) || matches[match.index].score < match.score
      matches[match.index] = match
    end

    matches
  end

  def initialize(@quality : Float32, @score : Int32, @index : Int32); end

  def <=>(other : self) : Int32
    if @quality != other.quality
      return @quality > other.quality ? -1 : 1
    end

    if @index != other.index
      return @index > other.index ? 1 : -1
    end

    0
  end
end
