# An extension of `ANG::Negotiator` that supports resolving the format based on an applications `ATH::Bundle::Schema::FormatListener` rules.
#
# See the [Getting Started](/getting_started/routing#content-negotiation) docs for more information.
class Athena::Framework::View::FormatNegotiator < ANG::Negotiator
  # :nodoc:
  record Rule,
    priorities : Array(String)? = nil,
    fallback_format : String | Bool | Nil = false,
    stop : Bool = false,
    prefer_extension : Bool = true

  @map : Array({ATH::RequestMatcher::Interface, ATH::View::FormatNegotiator::Rule}) = [] of {ATH::RequestMatcher::Interface, ATH::View::FormatNegotiator::Rule}

  def initialize(
    @request_store : ATH::RequestStore,
    @mime_types : Hash(String, Array(String)) = Hash(String, Array(String)).new,
  )
  end

  protected def add(request_matcher : ATH::RequestMatcher::Interface, rule : Rule) : Nil
    @map << {request_matcher, rule}
  end

  # :inherit:
  # ameba:disable Metrics/CyclomaticComplexity
  def best(header : String, priorities : Indexable(String)? = nil, strict : Bool = false) : HeaderType?
    request = @request_store.request

    header = header.presence || request.headers["accept"]?
    extension_header = nil

    @map.each do |(matcher, rule)|
      next unless matcher.matches? request

      if rule.stop
        raise ATH::Exception::StopFormatListener.new "Stopping format listener."
      end

      if priorities.nil? && rule.priorities.nil?
        if fallback_format = rule.fallback_format
          request.mime_type(fallback_format.as(String)).try do |mime_type|
            return ANG::Accept.new mime_type
          end
        end

        next
      end

      if rule.prefer_extension && extension_header.nil?
        if (extension = Path.new(request.path).extension.lchop '.').presence
          extension_header = request.mime_type extension

          header = %(#{extension_header}; q=2.0#{(h = header.presence) ? ",#{h}" : ""})
        end
      end

      if h = header.presence
        # Priorities defined on the rule wont be nil at this point it would have been skipped
        mime_types = self.normalize_mime_types priorities || rule.priorities.not_nil!

        if mime_type = super h, mime_types
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

    nil
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
