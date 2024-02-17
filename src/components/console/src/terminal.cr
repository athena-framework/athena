require "./ext/terminal"

# :nodoc:
struct Athena::Console::Terminal
  @@width : Int32? = nil
  @@height : Int32? = nil
  @@stty : Bool = false

  def self.has_stty_available? : Bool
    if stty = @@stty
      return stty
    end

    @@stty = !Process.find_executable("stty").nil?
  end

  def width : Int32
    if env_width = ENV["COLUMNS"]?
      return env_width.to_i
    end

    if @@width.nil?
      self.class.init_dimensions
    end

    @@width || 80
  end

  def height : Int32
    if env_height = ENV["LINES"]?
      return env_height.to_i
    end

    if @@height.nil?
      self.class.init_dimensions
    end

    @@height || 50
  end

  def size : {Int32, Int32}
    return self.width, self.height
  end

  private def self.check_size(size) : Bool
    if size && (cols = size[0]) && (rows = size[1]) && cols != 0 && rows != 0
      @@width = cols
      @@height = rows

      return true
    end

    false
  end

  {% if flag?(:win32) %}
    protected def self.init_dimensions : Nil
      return if check_size(size_from_screen_buffer)
      return if check_size(size_from_ansicon)
    end

    # Detect terminal size Windows `GetConsoleScreenBufferInfo`.
    private def self.size_from_screen_buffer
      LibC.GetConsoleScreenBufferInfo(LibC.GetStdHandle(LibC::STDOUT_HANDLE), out csbi)
      rows = csbi.srWindow.right - csbi.srWindow.left + 1
      cols = csbi.srWindow.bottom - csbi.srWindow.top + 1

      {cols.to_i32, rows.to_i32}
    end

    # Detect terminal size from Windows ANSICON
    private def self.size_from_ansicon
      return unless ENV["ANSICON"]?.to_s =~ /\((.*)x(.*)\)/

      rows, cols = [$2, $1].map(&.to_i)
      {cols, rows}
    end
  {% else %}
    protected def self.init_dimensions : Nil
      return if self.check_size(self.size_from_ioctl(0)) # STDIN
      return if self.check_size(self.size_from_ioctl(1)) # STDOUT
      return if self.check_size(self.size_from_ioctl(2)) # STDERR
      return if self.check_size(self.size_from_tput)
      return if self.check_size(self.size_from_stty)
    end

    # Read terminal size from Unix ioctl
    private def self.size_from_ioctl(fd)
      winsize = uninitialized LibC::Winsize
      ret = LibC.ioctl(fd, LibC::TIOCGWINSZ, pointerof(winsize))
      return if ret < 0

      {winsize.ws_col.to_i32, winsize.ws_row.to_i32}
    end

    # Detect terminal size from tput utility
    private def self.size_from_tput
      return unless STDOUT.tty?

      lines = `tput lines`.to_i?
      cols = `tput cols`.to_i?

      {cols, lines}
    rescue
      nil
    end

    # Detect terminal size from stty utility
    private def self.size_from_stty
      return unless STDOUT.tty?

      parts = `stty size`.split(/\s+/)
      return unless parts.size > 1
      lines, cols = parts.map(&.to_i?)

      {cols, lines}
    rescue
      nil
    end
  {% end %}
end
