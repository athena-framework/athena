@[ADI::Register]
# An extension of `ANG::Negotiator` that supports resolving the format based on an applications `ATH::Config::ContentNegotiation` rules.
#
# See the [negotiation](/architecture/negotiation) component for more information.
class Athena::Framework::View::FormatNegotiator < ANG::Negotiator
  private getter! config : ATH::Config::ContentNegotiation?

  def initialize(
    @request_store : ATH::RequestStore,
    @config : ATH::Config::ContentNegotiation?,
    @mime_types : Hash(String, Array(String)) = Hash(String, Array(String)).new
  ); end

  # :inherit:
  # ameba:disable Metrics/CyclomaticComplexity
  def best(header : String, priorities : Indexable(String)? = nil, strict : Bool = false) : HeaderType?
    return if @config.nil?

    request = @request_store.request

    header = header.presence || request.headers["accept"]?

    self.config.rules.each do |rule|
      # TODO: Abstract request matching logic into a dedicated service.
      next unless request.path.matches? rule.path
      if methods = rule.methods
        next unless methods.includes? request.method
      end

      if (host_pattern = rule.host) && (hostname = request.hostname)
        next unless host_pattern.matches? hostname
      end

      raise ATH::Exceptions::StopFormatListener.new "Stopping format listener." if rule.stop?

      if priorities.nil? && rule.priorities.nil?
        if (fallback_format = rule.fallback_format)
          request.mime_type(fallback_format.as(String)).try do |mime_type|
            return ANG::Accept.new mime_type
          end
        end

        next
      end

      # TODO: Support using the request path extension to determine the format.
      # This would require being able to define routes like `/foo.{_format}` first however.

      if header
        # Priorities defined on the rule wont be nil at this point it would have been skipped
        mime_types = self.normalize_mime_types priorities || rule.priorities.not_nil!

        if mime_type = super header, mime_types
          return mime_type
        end
      end

      rule.fallback_format.try do |ff|
        return if false == ff

        request.mime_type(ff.as(String)).try do |mt|
          return ANG::Accept.new mt
        end
      end
    end
  end

  private def normalize_mime_types(priorities : Indexable(String)) : Array(String)
    priorities = priorities.map &.gsub(/\s+/, "").downcase

    mime_types = [] of String

    priorities.each do |priority|
      if priority.includes? '/'
        mime_types << priority

        next
      end

      mime_types = mime_types.concat ATH::Request.mime_types priority

      if @mime_types.has_key? priority
        mime_types.concat @mime_types[priority]
      end
    end

    mime_types
  end
end
