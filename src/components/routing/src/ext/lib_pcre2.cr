@[Link("pcre2-8")]
lib LibPCRE2
  ERROR_NOMATCH = -1

  JIT_COMPLETE = 0x00000001

  INFO_CAPTURECOUNT  =  4
  INFO_NAMECOUNT     = 17
  INFO_NAMEENTRYSIZE = 18
  INFO_NAMETABLE     = 19

  type MatchData = Void*

  alias Code = Void*
  alias CompileContext = Void*
  alias GeneralContext = Void*
  alias MatchContext = Void*

  alias UCHAR = LibC::UChar*
  alias SPTR = UInt8*
  alias SIZE = LibC::SizeT
  alias UInt32T = LibC::UInt

  fun compile = pcre2_compile_8(pattern : SPTR, length : SIZE, options : UInt32T, error_code : LibC::Int*, error_offset : SIZE*, compile_context : CompileContext) : Code
  fun jit_compile = pcre2_jit_compile_8(code : Code, options : UInt32T) : LibC::Int
  fun create_match_data = pcre2_match_data_create_from_pattern_8(code : Code, general_context : GeneralContext) : MatchData
  fun jit_match = pcre2_jit_match_8(code : Code, subject : SPTR, length : SIZE, start_offset : SIZE, options : UInt32T, match_data : MatchData, match_context : MatchContext) : LibC::Int
  fun get_ovector = pcre2_get_ovector_pointer_8(match_data : MatchData) : SIZE*

  fun pattern_info = pcre2_pattern_info_8(code : Code, what : UInt32T, where : LibC::Int*) : LibC::Int
  fun get_mark = pcre2_get_mark_8(match_data : MatchData) : SPTR

  fun get_error_message = pcre2_get_error_message_8(error_code : LibC::Int, buffer : UCHAR, buffer_length : SIZE) : LibC::Int
end
