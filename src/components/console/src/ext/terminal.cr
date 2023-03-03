{% if flag?(:win32) %}
  lib LibC
    struct COORD
      x : Int16
      y : Int16
    end

    struct SMALL_RECT
      left : Int16
      top : Int16
      right : Int16
      bottom : Int16
    end

    struct CONSOLE_SCREEN_BUFFER_INFO
      dwSize : COORD
      dwCursorPosition : COORD
      wAttributes : UInt16
      srWindow : SMALL_RECT
      dwMaximumWindowSize : COORD
    end

    STD_INPUT_HANDLE  = -10
    STD_OUTPUT_HANDLE = -11
    STD_ERROR_HANDLE  = -12

    fun GetConsoleScreenBufferInfo(hConsoleOutput : Void*, lpConsoleScreenBufferInfo : CONSOLE_SCREEN_BUFFER_INFO*) : Void
    fun GetStdHandle(nStdHandle : UInt32) : Void*
  end
{% else %}
  lib LibC
    struct Winsize
      ws_row : UShort
      ws_col : UShort
      ws_xpixel : UShort
      ws_ypixel : UShort
    end

    # TIOCGWINSZ is a platform dependent magic number passed to ioctl that requests the current terminal window size.
    # Values lifted from https://github.com/crystal-term/screen/blob/ea51ee8d1f6c286573c41a7e784d31c80af7b9bb/src/term-screen.cr#L86-L88.
    {% begin %}
      {% if flag?(:darwin) || flag?(:bsd) %}
        TIOCGWINSZ = 0x40087468
      {% elsif flag?(:unix) %}
        TIOCGWINSZ = 0x5413
      {% else %} # Solaris
        TIOCGWINSZ = 0x5468
      {% end %}
    {% end %}

    fun ioctl(fd : Int, request : ULong, ...) : Int
  end
{% end %}
