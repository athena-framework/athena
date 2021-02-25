@[ADI::Register]
class Athena::Routing::View::FormatNegotiator < ANG::Negotiator
  def initialize(
    @request_store : ART::RequestStore,
    @configuration_resolver : ACF::ConfigurationResolverInterface,
    @mime_types : Array(String) = [] of String
  ); end

  def best(header : String, priorities : Indexable(String)? = nil, strict : Bool = false) : HeaderType?
    request = @request_store.request

    header = header.presence || request.headers["accept"]?

    return unless config = @configuration_resolver.resolve(ART::Config::ContentNegotiation)

    pp config

    config.rules.each do |rule|
      next unless request.path.matches? rule.path
      next unless rule.methods.try &.includes? request.method

      if priorities.nil? && rule.priorities.nil?
        if (fallback_format = rule.fallback_format)
          request.mime_type(fallback_format.as(String)).try do |mime_type|
            return ANG::Accept.new mime_type
          end
        end

        next
      end

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
    !@configuration_resolver.resolve(ART::Config::ContentNegotiation).nil?
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
    end

    mime_types
  end
end
