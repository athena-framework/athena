{% if flag?(:win32) %}
  lib LibC
    STDOUT_HANDLE = 0xFFFFFFF5

    struct Point
      x : UInt16
      y : UInt16
    end

    struct SmallRect
      left : UInt16
      top : UInt16
      right : UInt16
      bottom : UInt16
    end

    struct ScreenBufferInfo
      dwSize : Point
      dwCursorPosition : Point
      wAttributes : UInt16
      srWindow : SmallRect
      dwMaximumWindowSize : Point
    end

    alias Handle = Void*
    alias ScreenBufferInfoPtr = ScreenBufferInfo*

    fun GetConsoleScreenBufferInfo(handle : Handle, info : ScreenBufferInfoPtr) : Bool
    fun GetStdHandle(handle : UInt32) : Handle
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
