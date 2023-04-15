# :nodoc:
module Athena::Routing::RouteCompiler
  private PATH_REGEX = /{(!)?(\w+)}/
  private SEPARATORS = "/,;.:-_~+*=@|"
  private MAX_LENGTH = 32

  private record CompiledPattern,
    static_prefix : String,
    regex : Regex,
    tokens : Array(ART::CompiledRoute::Token),
    variables : Set(String)

  def self.compile(route : Route) : CompiledRoute
    host_variables = Set(String).new
    variables = Set(String).new
    host_regex = nil
    host_tokens = Array(ART::CompiledRoute::Token).new

    if host = route.host.presence
      pattern = self.compile_pattern route, host, true

      host_variables = pattern.variables
      variables = host_variables.dup

      host_tokens = pattern.tokens
      host_regex = pattern.regex
    end

    if (locale = route.default "_locale") && !route.default("_canonical_route").nil? && route.requirement("_locale").try &.source == Regex.escape(locale)
      requirements = route.requirements
      requirements.delete "_locale"

      # TODO: Pretty sure this deletes via reference
      route.requirements = requirements
      route.path = route.path.sub "{_locale}", locale
    end

    path = route.path

    pattern = self.compile_pattern route, path, false

    path_variables = pattern.variables

    raise ART::Exception::InvalidArgument.new "Route pattern '#{route.path}' cannot contain '_fragment' as a path parameter." if path_variables.includes? "_fragment"

    variables.concat path_variables

    CompiledRoute.new(
      pattern.static_prefix,
      pattern.regex,
      pattern.tokens,
      path_variables,
      host_regex,
      host_tokens,
      host_variables,
      variables
    )
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def self.compile_pattern(route : Route, pattern : String, is_host : Bool)
    pos = 0
    variables = Set(String).new
    tokens = Array(ART::CompiledRoute::Token).new
    default_separator = is_host ? "." : "/"

    # Matches and iterates over all variables within `{}`.
    # match[0] => var name with {}
    # match[1] => (optional) `!` symbol
    # match[2] => var name without {}
    pattern.scan(PATH_REGEX) do |match|
      is_important = !match[1]?.nil?
      var_name = match[2]

      # Static text before the match
      preceding_text = pattern[pos, match.begin - pos]
      pos = match.begin + match[0].size

      preceding_char = preceding_text.empty? ? "" : preceding_text[-1].to_s
      is_separator = !preceding_char.empty? && SEPARATORS.includes?(preceding_char)

      raise ART::Exception::InvalidArgument.new "Variable name '#{var_name}' cannot start with a digit in route pattern '#{pattern}'." if var_name.starts_with? /\d/
      raise ART::Exception::InvalidArgument.new "Route pattern '#{pattern}' cannot reference variable name '#{var_name}' more than once." unless variables.add? var_name
      raise ART::Exception::InvalidArgument.new "Variable name '#{var_name}' cannot be longer than #{MAX_LENGTH} characters in route pattern '#{pattern}'." if var_name.size > MAX_LENGTH

      if is_separator && preceding_text != preceding_char
        tokens << ART::CompiledRoute::Token.new :text, preceding_text[0...-preceding_char.size]
      elsif !is_separator && !preceding_text.empty?
        tokens << ART::CompiledRoute::Token.new :text, preceding_text
      end

      if regex = route.requirement var_name
        regex = self.transform_capturing_groups_to_non_capturings regex.source
      else
        following_pattern = pattern[pos..]
        next_separator = self.find_next_separator following_pattern

        regex = /[^#{Regex.escape default_separator}#{default_separator != next_separator && "" != next_separator ? Regex.escape(next_separator) : ""}]+/

        if (!next_separator.empty? && !following_pattern.matches?(/^\{\w+\}/)) || following_pattern.empty?
          regex = /#{regex.source}+/
        end
      end

      tokens << if is_important
        ART::CompiledRoute::Token.new :variable, is_separator ? preceding_char : "", regex, var_name, true
      else
        ART::CompiledRoute::Token.new :variable, is_separator ? preceding_char : "", regex, var_name
      end
    end

    if pos < pattern.size
      tokens << ART::CompiledRoute::Token.new :text, pattern[pos..]
    end

    first_optional_index = Int32::MAX

    unless is_host
      idx = tokens.size - 1

      while idx >= 0
        token = tokens[idx]

        break if !token.type.variable? || token.important? || !route.has_default?(token.var_name.not_nil!)

        first_optional_index = idx
        idx -= 1
      end
    end

    route_pattern = ""
    tokens.each_with_index do |_, i|
      route_pattern += self.compute_regex tokens, i, first_optional_index
    end

    route_regex = Regex.new "^#{route_pattern}$", is_host ? Regex::CompileOptions::IGNORE_CASE : Regex::CompileOptions::None

    # Crystal has UTF-8 regex mode enabled by default, so no need to add it.

    CompiledPattern.new(
      self.determine_static_prefix(route, tokens),
      route_regex,
      tokens.reverse!,
      variables
    )
  end

  private def self.determine_static_prefix(route : Route, tokens : Array(ART::CompiledRoute::Token)) : String
    first_token = tokens.first

    unless first_token.type.text?
      return (route.has_default?(first_token.var_name.not_nil!) || "/" == first_token.prefix) ? "" : first_token.prefix
    end

    prefix = first_token.prefix

    if (second_token = tokens[1]?) && ("/" != second_token.prefix) && !route.has_default?(second_token.var_name.not_nil!)
      prefix += second_token.prefix
    end

    prefix
  end

  private def self.find_next_separator(pattern : String) : String
    return "" if pattern.empty?
    return "" if (pattern = pattern.gsub(/\{\w+\}/, "")).empty?

    pattern = pattern[0].to_s

    SEPARATORS.includes?(pattern) ? pattern : ""
  end

  private def self.compute_regex(tokens : Array(ART::CompiledRoute::Token), idx : Int, first_optional_index : Int) : String
    token = tokens[idx]

    case token.type
    in .text? then Regex.escape token.prefix
    in .variable?
      if idx.zero? && 0 == first_optional_index
        "#{Regex.escape token.prefix}(?P<#{token.var_name}>#{token.regex.not_nil!.source})?"
      else
        regex = "#{Regex.escape token.prefix}(?P<#{token.var_name}>#{token.regex.not_nil!.source})"

        if idx >= first_optional_index
          regex = "(?:#{regex}"
          num_tokens = tokens.size

          if idx == num_tokens - 1
            regex += ")?" * (num_tokens - first_optional_index - (first_optional_index.zero? ? 1 : 0))
          end
        end

        regex
      end
    end
  end

  private def self.transform_capturing_groups_to_non_capturings(source : String) : Regex
    idx = 0
    while idx < source.size
      if '\\' == source[idx]
        idx += 2
        next
      end

      if '(' != source[idx] || source[idx + 2]?.nil?
        idx += 1
        next
      end

      if '*' == source[(idx += 1)] || '?' == source[idx]
        idx += 2
        next
      end

      source = source.insert idx, "?:"
      idx += 1
    end

    Regex.new source
  end
end
