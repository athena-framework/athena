require "./lib_pcre2"

# :nodoc:
#
# Specialized re-implementation of stdlib's regex, but with `PCRE2` using the fast track API.
class Athena::Routing::FastRegex
  struct MatchData
    getter group_size : Int32
    getter mark : String?

    # :nodoc:
    def initialize(@string : String, @ovector : LibC::SizeT*, @group_size : Int32, @mark : String?)
    end

    def size : Int32
      group_size + 1
    end

    def []?(n : Int) : String?
      return unless valid_group?(n)

      start = @ovector[n * 2]
      finish = @ovector[n * 2 + 1]

      # TODO: Figure out what this should actually be.
      return if start > Int32::MAX || finish > Int32::MAX
      @string.byte_slice(start, finish - start)
    end

    def [](n : Int) : String
      check_index_out_of_bounds n
      n += size if n < 0

      value = self[n]?
      raise_capture_group_was_not_matched n if value.nil?
      value
    end

    private def check_index_out_of_bounds(index)
      raise_invalid_group_index(index) unless valid_group?(index)
    end

    private def valid_group?(index)
      -size <= index < size
    end

    private def raise_invalid_group_index(index)
      raise IndexError.new("Invalid capture group index: #{index}")
    end

    private def raise_capture_group_was_not_matched(index)
      raise IndexError.new("Capture group #{index} was not matched")
    end
  end

  getter source : String

  @mark : UInt8* = Pointer(UInt8).null
  @capture_count : Int32 = 0

  def initialize(@source : String)
    # Automatically apply `DOTALL` and `DOLLAR_ENDONLY` options.
    unless @code = LibPCRE2.compile @source, @source.bytesize, LibPCRE2::DOLLAR_ENDONLY | LibPCRE2::DOTALL, out error_code, out error_offset, nil
      bytes = Bytes.new 128
      LibPCRE2.get_error_message(error_code, bytes, bytes.size)
      raise ArgumentError.new "#{String.new(bytes)} at #{error_offset}"
    end

    @jit = 0 == LibPCRE2.jit_compile @code, LibPCRE2::JIT_COMPLETE

    capture_count = uninitialized UInt32
    LibPCRE2.pattern_info @code, LibPCRE2::INFO_CAPTURECOUNT, pointerof(capture_count)
    @capture_count = capture_count.to_i

    @match_data = LibPCRE2.match_data_create_from_pattern @code, nil
  end

  def match(str, pos = 0) : MatchData?
    if byte_index = str.char_index_to_byte_index(pos)
      match_at_byte_index(str, byte_index)
    else
      nil
    end
  end

  def match_at_byte_index(str, byte_index = 0) : MatchData?
    return if byte_index > str.bytesize
    return unless internal_matches(str, byte_index)
    Athena::Routing::FastRegex::MatchData.new(str, LibPCRE2.get_ovector_pointer(@match_data), @capture_count, ((mark = LibPCRE2.get_mark(@match_data)) ? String.new(mark) : nil))
  end

  def ==(other : FastRegex)
    @source == other.@source
  end

  def inspect(io : IO) : Nil
    io << '/'
    reader = Char::Reader.new(@source)
    while reader.has_next?
      case char = reader.current_char
      when '\\'
        io << '\\'
        io << reader.next_char
      when '/'
        io << "\\/"
      else
        io << char
      end
      reader.next_char
    end
    io << '/'
  end

  private def internal_matches(str, byte_index) : Bool
    match_count = if @jit
                    LibPCRE2.jit_match @code, str, str.bytesize, byte_index, LibPCRE2::NO_UTF_CHECK, @match_data, nil
                  else
                    LibPCRE2.match @code, str, str.bytesize, byte_index, LibPCRE2::NO_UTF_CHECK, @match_data, nil
                  end

    if match_count < 0
      case error = LibPCRE2::Error.new(match_count)
      when .nomatch?
        return false
      else
        raise ::Exception.new("Regex match error: #{error}")
      end
    end

    true
  end
end
