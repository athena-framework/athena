# An `ACON::Input::Interface` based on a command line string.
class Athena::Console::Input::StringLine < Athena::Console::Input::ARGV
  private REGEX_UNQUOTED_STRING = /([^\s\\]+?)/
  private REGEX_QUOTED_STRING   = /(?:"([^"\\]*(?:\\.[^"\\]*)*)"|\'([^\'\\]*(?:\\.[^\'\\]*)*)\')/

  def initialize(input : String)
    super [] of String

    @tokens = self.tokenize input
  end

  private def tokenize(input : String) : Array(String)
    tokens = [] of String
    length = input.size
    idx = 0
    token = ""

    while idx < length
      if '\\' == input[idx]
        idx += 1
        token += input[idx]? || ""
        idx += 1
        next
      end

      match = if m = input.match /\G\s+/, idx
                unless token.blank?
                  tokens << token
                  token = ""
                end

                m
              elsif m = input.match /\G([^="\'\s]+?)(=?)(#{REGEX_QUOTED_STRING}+)/, idx
                token += %(#{m[1]}#{m[2]}#{m[3][1...-1].gsub(/("\'|\'"|\'\'|\"\")/, "").gsub(/\\'/, {"\\'" => "'"})})
                m
              elsif m = input.match /\G#{REGEX_QUOTED_STRING}/, idx
                token += m[0][1...-1].gsub(/\\'/, {"\\'" => "'"})
                m
              elsif m = input.match /\G#{REGEX_UNQUOTED_STRING}/, idx
                token += m[1]
                m
              else
                raise ArgumentError.new "Unable to parse input neat '... #{input[idx, 10]} ...'."
              end

      idx += match[0].size
    end

    tokens << token unless token.blank?

    tokens
  end
end
