lib LibPCRE2
  fun jit_match = pcre2_jit_match_8(code : Code*, subject : UInt8*, length : LibC::SizeT, startoffset : LibC::SizeT, options : UInt32, match_data : MatchData*, mcontext : MatchContext*) : Int
  fun get_mark = pcre2_get_mark_8(match_data : MatchData*) : UInt8*
end

# Customizations to stdlib Regex logic to support fast path API and MARK verb

class Regex
  def self.fast_path(source : String, options : Options = Options::None)
    new(_source: source, _options: options, _force_jit: true)
  end
end

module Regex::PCRE2
  module MatchData
    getter mark : String?

    def initialize(
      @regex : Regex,
      @code : LibPCRE2::Code*,
      @string : String,
      @pos : Int32,
      @ovector : LibC::SizeT*,
      @group_size : Int32,
      @mark : String?,
    )
    end
  end

  @force_jit : Bool = false

  def initialize(*, _source @source : String, _options @options, _force_jit @force_jit : Bool = false)
    options = pcre2_compile_options(options) | LibPCRE2::UTF | LibPCRE2::DUPNAMES | LibPCRE2::UCP
    @re = PCRE2.compile(source, options) do |error_message|
      raise ArgumentError.new(error_message)
    end

    @jit = jit_compile
  end

  private def match_data(str, byte_index, options)
    match_data = self.match_data

    # CUSTOMIZE - Leverage JIT Fast Path mode if available
    match_count = if @jit && @force_jit
                    LibPCRE2.jit_match(@re, str, str.bytesize, byte_index, pcre2_match_options(options), match_data, PCRE2.match_context)
                  else
                    LibPCRE2.match(@re, str, str.bytesize, byte_index, pcre2_match_options(options), match_data, PCRE2.match_context)
                  end

    if match_count < 0
      case error = LibPCRE2::Error.new(match_count)
      when .nomatch?
        return
      when .badutfoffset?, .utf8_validity?
        error_message = PCRE2.get_error_message(error)
        raise ArgumentError.new("Regex match error: #{error_message}")
      else
        error_message = PCRE2.get_error_message(error)
        raise Regex::Error.new("Regex match error: #{error_message}")
      end
    end

    match_data
  end

  private def match_impl(str, byte_index, options)
    match_data = match_data(str, byte_index, options) || return

    ovector_count = LibPCRE2.get_ovector_count(match_data)
    ovector = Slice.new(LibPCRE2.get_ovector_pointer(match_data), ovector_count &* 2)

    # We need to dup the ovector because `match_data` is re-used for subsequent
    # matches (see `@match_data`).
    # Dup brings the ovector data into the realm of the GC.
    ovector = ovector.dup

    ::Regex::MatchData.new(
      self,
      @re,
      str,
      byte_index,
      ovector.to_unsafe,
      ovector_count.to_i32 &- 1,

      # CUSTOMIZE - Get MARK verb
      ((mark = LibPCRE2.get_mark(match_data)) ? String.new(mark) : nil)
    )
  end
end

module Athena::Routing
  protected def self.create_regex(source : String) : ::Regex
    ::Regex.fast_path source, ::Regex::CompileOptions[:dotall, :dollar_endonly, :no_utf8_check]
  end
end
