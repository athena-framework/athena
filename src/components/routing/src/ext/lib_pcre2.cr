{% if @top_level.has_constant? "LibPCRE2" %}
  @[Link("pcre2-8")]
  lib LibPCRE2
    fun jit_match = pcre2_jit_match_8(code : Code*, subject : UInt8*, length : LibC::SizeT, startoffset : LibC::SizeT, options : UInt32, match_data : MatchData*, mcontext : MatchContext*) : Int
    fun get_mark = pcre2_get_mark_8(match_data : MatchData*) : UInt8*
  end
{% else %}
  @[Link("pcre2-8")]
  lib LibPCRE2
    alias Int = LibC::Int

    NO_UTF_CHECK   = 0x40000000
    DOLLAR_ENDONLY = 0x00000010
    DOTALL         = 0x00000020

    enum Error
      NOMATCH = -1
    end

    JIT_COMPLETE = 0x00000001

    INFO_CAPTURECOUNT  =  4
    INFO_NAMECOUNT     = 17
    INFO_NAMEENTRYSIZE = 18
    INFO_NAMETABLE     = 19

    type Code = Void
    type CompileContext = Void
    type GeneralContext = Void
    type MatchContext = Void
    type MatchData = Void

    fun compile = pcre2_compile_8(pattern : UInt8*, length : LibC::SizeT, options : UInt32, errorcode : Int*, erroroffset : LibC::SizeT*, ccontext : CompileContext*) : Code*
    fun jit_compile = pcre2_jit_compile_8(code : Code*, options : UInt32) : Int
    fun match_data_create_from_pattern = pcre2_match_data_create_from_pattern_8(code : Code*, gcontext : GeneralContext*) : MatchData*
    fun jit_match = pcre2_jit_match_8(code : Code*, subject : UInt8*, length : LibC::SizeT, startoffset : LibC::SizeT, options : UInt32, match_data : MatchData*, mcontext : MatchContext*) : Int
    fun match = pcre2_match_8(code : Code*, subject : UInt8*, length : LibC::SizeT, startoffset : LibC::SizeT, options : UInt32, match_data : MatchData*, mcontext : MatchContext*) : Int
    fun get_ovector_pointer = pcre2_get_ovector_pointer_8(match_data : MatchData*) : LibC::SizeT*

    fun pattern_info = pcre2_pattern_info_8(code : Code*, what : UInt32, where : Void*) : Int
    fun get_mark = pcre2_get_mark_8(match_data : MatchData*) : LibC::Char*

    fun get_error_message = pcre2_get_error_message_8(errorcode : Int, buffer : UInt8*, bufflen : LibC::SizeT) : Int
  end
{% end %}
