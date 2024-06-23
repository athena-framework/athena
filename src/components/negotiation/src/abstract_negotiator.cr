# Base negotiator type.  Implements logic common to all negotiators.
abstract class Athena::Negotiation::AbstractNegotiator(HeaderType)
  private record OrderKey, quality : Float32, index : Int32, value : String do
    include Comparable(self)

    def <=>(other : self) : Int32
      return @index <=> other.index if @quality == other.quality
      @quality > other.quality ? -1 : 1
    end
  end

  # Returns the best `HeaderType` based on the provided *header* value and *priorities*.
  #
  # If *strict* is `true`, an `ANG::Exception::Exception` will be raised if the *header* contains an invalid value, otherwise it is ignored.
  #
  # See `Athena::Negotiation` for examples.
  def best(header : String, priorities : Indexable(String), strict : Bool = false) : HeaderType?
    raise ANG::Exception::InvalidArgument.new "priorities should not be empty." if priorities.empty?
    raise ANG::Exception::InvalidArgument.new "The header string should not be empty." if header.blank?

    accepted_headers = Array(HeaderType).new

    self.parse_header(header) do |h|
      accepted_headers << HeaderType.new h
    rescue ex
      raise ex if strict
    end

    accepted_priorties = priorities.map { |p| HeaderType.new p }

    matches = self.find_matches accepted_headers, accepted_priorties

    specific_matches = matches.reduce({} of Int32 => ANG::AcceptMatch) do |acc, match|
      ANG::AcceptMatch.reduce acc, match
    end.values

    specific_matches.sort!

    match = specific_matches.shift?

    match.nil? ? nil : accepted_priorties[match.index]
  end

  # Returns an array of `HeaderType` that the provided *header* allows, ordered so that the `#best` match is first.
  #
  # ```
  # header = "text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5"
  #
  # ordered_elements = ANG.negotiator.ordered_elements header
  #
  # ordered_elements[0].media_range # => "text/html"
  # ordered_elements[1].media_range # => "text/html"
  # ordered_elements[2].media_range # => "*/*"
  # ordered_elements[3].media_range # => "text/html"
  # ordered_elements[4].media_range # => "text/*"
  # ```
  def ordered_elements(header : String) : Array(HeaderType)
    raise ANG::Exception::InvalidArgument.new "The header string should not be empty." if header.blank?

    elements = Array(HeaderType).new
    order_keys = Array(OrderKey).new

    idx = 0
    self.parse_header(header) do |h|
      element = HeaderType.new h
      elements << element
      order_keys << OrderKey.new element.quality, idx, element.header
    rescue ex
      # skip
    ensure
      idx += 1
    end

    order_keys.sort!.map do |ok|
      elements[ok.index]
    end
  end

  protected def match(header : ANG::BaseAccept, priority : ANG::BaseAccept, index : Int32) : ANG::AcceptMatch?
    accept_value = header.accept_value
    priority_value = priority.accept_value

    equal = accept_value.downcase == priority_value.downcase

    if equal || accept_value == "*"
      return ANG::AcceptMatch.new header.quality * priority.quality, 1 * (equal ? 1 : 0), index
    end

    nil
  end

  private def parse_header(header : String, & : String ->) : Nil
    header.scan /(?:[^,\"]*+(?:"[^"]*+\")?)+[^,\"]*+/ do |match|
      yield match[0].strip unless match[0].blank?
    end
  end

  private def find_matches(headers : Array(HeaderType), priorities : Indexable(HeaderType)) : Array(ANG::AcceptMatch)
    matches = [] of ANG::AcceptMatch

    priorities.each_with_index do |priority, idx|
      headers.each do |header|
        if match = self.match(header, priority, idx)
          matches << match
        end
      end
    end

    matches
  end
end
