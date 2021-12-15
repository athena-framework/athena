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

  protected def self.init_dimensions : Nil
    # TODO: Support Windows
    {% raise "Athena::Console component does not support Windows yet." if flag?(:win32) %}

    self.init_dimensions_via_stty
  end

  private def self.init_dimensions_via_stty : Nil
    return unless stty_info = self.stty_columns

    if match = stty_info.match /rows.(\d+);.columns.(\d+);/i
      @@height = match[1].to_i
      @@width = match[2].to_i
    elsif match = stty_info.match /;.(\d+).rows;.(\d+).columns/i
      @@height = match[1].to_i
      @@width = match[2].to_i
    end
  end

  private def self.stty_columns : String?
    stty_info = `stty -a | grep columns`

    return nil unless $?.success?

    stty_info
  end
end
