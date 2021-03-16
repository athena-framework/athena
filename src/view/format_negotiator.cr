@[ADI::Register]
class Athena::Routing::View::FormatNegotiator < ANG::Negotiator
  private getter! config : ART::Config::ContentNegotiation?

  def initialize(
    @request_store : ART::RequestStore,
    @config : ART::Config::ContentNegotiation?,
    @mime_types : Hash(String, Array(String)) = Hash(String, Array(String)).new
  ); end

  # ameba:disable Metrics/CyclomaticComplexity
  def best(header : String, priorities : Indexable(String)? = nil, strict : Bool = false) : HeaderType?
    return if @config.nil?

    request = @request_store.request

    header = header.presence || request.headers["accept"]?

    self.config.rules.each do |rule|
      next unless request.path.matches? rule.path
      if methods = rule.methods
        next unless methods.includes? request.method
      end

      raise ART::Exceptions::StopFormatListener.new "Stopping format listener." if rule.stop?

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

  def enabled? : Bool
    !@config.nil?
  end

  private def normalize_mime_types(priorities : Indexable(String)) : Array(String)
    priorities = priorities.map &.gsub(/\s+/, "").downcase

    mime_types = [] of String

    priorities.each do |priority|
      if priority.includes? '/'
        mime_types << priority

        next
      end

      mime_types = mime_types.concat HTTP::Request.mime_types priority

      if @mime_types.has_key? priority
        mime_types.concat @mime_types[priority]
      end
    end

    mime_types
  end
end
