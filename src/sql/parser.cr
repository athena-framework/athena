require "./parser/visitor"
require "./parser/convert_parameters"

# :nodoc:
module Athena::ORM::SQL
  # :nodoc:
  #
  # Parses SQL strings and dispatches tokens to a visitor.
  # Correctly handles parameters inside string literals, comments, and quoted identifiers.
  class Parser
    # Token patterns for SQL parsing

    # ANSI-style string literals: 'text' with '' for escaping
    # MySQL-style string literals: 'text' with \' for escaping
    private ANSI_STRING_LITERAL = /'(?:''|[^'])*'/

    # MySQL-style string with backslash escaping
    private MYSQL_STRING_LITERAL = /'(?:\\'|''|[^'])*'/

    # Double-quoted identifiers: "identifier"
    private DOUBLE_QUOTED_IDENTIFIER = /"(?:""|[^"])*"/

    # Backtick-quoted identifiers (MySQL style): `identifier`
    private BACKTICK_IDENTIFIER = /`(?:``|[^`])*`/

    # Square bracket identifiers (SQL Server style): [identifier]
    # Excludes PostgreSQL `ARRAY[...]` constructors, whose contents may hold parameters.
    private BRACKET_IDENTIFIER = /(?<!\b(?i:ARRAY))\[[^\]]*\]/

    # Runs of two or more colons, such as PostgreSQL's `::` cast operator, which must not be read as a named parameter.
    private MULTICHAR = /:{2,}/

    # Single-line comments: -- ...
    private LINE_COMMENT = /--[^\r\n]*/

    # Multi-line comments: /* ... */
    private BLOCK_COMMENT = /\/\*[\s\S]*?\*\//

    # Named parameters: :name
    private NAMED_PARAMETER = /:[a-zA-Z_][a-zA-Z0-9_]*/

    # Positional parameters: ? (but not ?? which is PostgreSQL's key-exists operator)
    private POSITIONAL_PARAMETER = /(?<!\?)\?(?!\?)/

    @token_pattern : Regex

    def initialize(@mysql_string_escaping : Bool = false)
      string_literal = @mysql_string_escaping ? MYSQL_STRING_LITERAL : ANSI_STRING_LITERAL

      # Build combined token pattern with named groups
      @token_pattern = Regex.new(
        "(?<string>#{string_literal.source})" \
        "|(?<dquote>#{DOUBLE_QUOTED_IDENTIFIER.source})" \
        "|(?<backtick>#{BACKTICK_IDENTIFIER.source})" \
        "|(?<bracket>#{BRACKET_IDENTIFIER.source})" \
        "|(?<multichar>#{MULTICHAR.source})" \
        "|(?<linecomment>#{LINE_COMMENT.source})" \
        "|(?<blockcomment>#{BLOCK_COMMENT.source})" \
        "|(?<named>#{NAMED_PARAMETER.source})" \
        "|(?<positional>#{POSITIONAL_PARAMETER.source})"
      )
    end

    # Parses the SQL string and dispatches tokens to the visitor.
    def parse(sql : String, visitor : Visitor) : Nil
      pos = 0

      sql.scan(@token_pattern) do |match|
        # Handle any text before this match
        if match.begin > pos
          visitor.accept_other(sql[pos...match.begin])
        end

        # Dispatch based on which group matched
        if match["positional"]?
          visitor.accept_positional_parameter(match[0])
        elsif match["named"]?
          visitor.accept_named_parameter(match[0])
        else
          # String literals, identifiers, and comments are passed through as-is
          visitor.accept_other(match[0])
        end

        pos = match.end
      end

      # Handle any remaining text after the last match
      if pos < sql.size
        visitor.accept_other(sql[pos..])
      end
    end
  end
end
