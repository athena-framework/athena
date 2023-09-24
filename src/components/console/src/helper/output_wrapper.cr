# :nodoc:
#
# Adapted from https://github.com/symfony/symfony/blob/fbf6f56ca7321e28d9a4368e18b9da683c296046/src/Symfony/Component/Console/Helper/OutputWrapper.php
struct Athena::Console::Helper::OutputWrapper
  def initialize(@allow_cut_urls : Bool = false); end

  def wrap(text : String, width : Int32, separator : String = "\n") : String
    return text if width.zero?

    row_pattern = if @allow_cut_urls
                    %r((?:<(?:(?:[a-z](?:[^\\<>]*+ | \\.)*)|/(?:[a-z][^<>]*+)?)>|.){1,#{width}})
                  else
                    %r((?:<(?:(?:[a-z](?:[^\\<>]*+ | \\.)*)|/(?:[a-z][^<>]*+)?)>|.|https?://\S+){1,#{width}})
                  end

    pattern = %r((?:((?>(#{row_pattern.source})((?<=[^\S\r\n])[^\S\r\n]?|(?=\r?\n)|$|[^\S\r\n]))|(#{row_pattern.source}))(?:\r?\n)?|(?:\r?\n|$)))imx

    text
      .gsub(pattern, "\\0#{separator}")
      .rstrip(separator)
      .gsub " #{separator}", separator
  end
end
