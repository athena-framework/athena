class Athena::Dotenv; end

require "./exceptions/*"

# All usage involves using an `Athena::Dotenv` instance.
# For example:
#
# ```
# require "athena-dotenv"
#
# # Create a new instance
# dotenv = Athena::Dotenv.new
#
# # Load a file
# dotenv.load "./.env"
#
# # Load multiple files
# dotenv.load "./.env", "./.env.dev"
#
# # Overrides existing variables
# dotenv.overload "./.env"
#
# # Load all files for the current $APP_ENV
# # .env, .env.local, and .env.$APP_ENV.local or .env.$APP_ENV
# dotenv.load_environment "./.env"
# ```
# A `Athena::Dotenv::Exceptions::Path` error will be raised if the provided file was not found, or is not readable.
#
# ## Syntax
#
# ENV vars should be defined one per line.
# There should be no space between the `=` between the var name and its value.
#
# ```text
# DATABASE_URL=mysql://db_user:db_password@127.0.0.1:3306/db_name
# ```
#
# A`Athena::Dotenv::Exceptions::Format` error will be raised if a formatting/parsing error is encountered.
#
# ### Comments
#
# Comments can be defined by prefixing them with a `#` character.
# Comments can defined on its own line, or inlined after an ENV var definition.
#
# ```text
# # Single line comment
# FOO=BAR
#
# BAR=BAZ # Inline comment
# ```
#
# ### Quotes
#
# Unquoted values, or those quoted with single (`'`) quotes behave as literals while double (`"`) quotes will have special chars expanded.
# For example, given the following `.env` file:
#
# ```text
# UNQUOTED=FOO\nBAR
# SINGLE_QUOTES='FOO\nBAR'
# DOUBLE_QUOTES="FOO\nBAR"
# ```
# ```
# require "athena-dotenv"
#
# Athena::Dotenv.new.load "./.env"
#
# ENV["UNQUOTED"]      # => "FOO\\nBAR"
# ENV["SINGLE_QUOTES"] # => "FOO\\nBAR"
# ENV["DOUBLE_QUOTES"] # => "FOO\n" + "BAR"
# ```
#
# Notice how only the double quotes version actually expands `\n` into a newline, whereas the others treat it as a literal `\n`.
#
# Quoted values may also extend over multiple lines:
#
# ```text
# FOO="FOO
# BAR\n
# BAZ"
# ```
#
# Both single and double quotes will include the actual newline characters, however only double quotes would expand the extra newline in `BAR\n`.
#
# ### Variables
#
# ENV vars can be used in values by prefixing the variable name with a `$` with optional opening and closing `{}`.
#
# ```text
# FOO=BAR
# BAZ=$FOO
# BIZ=${BAZ}
# ```
#
# WARNING: The order is important when using variables.
# In the previous example `FOO` must be defined `BAZ` which must be defined before `BIZ`.
# This also extends to when loading multiple files, where a variable may use the value in another file.
#
# Default values may also be defined in case the related ENV var is not set:
#
# ```text
# DB_USER=${DB_USER:-root}
# ```
#
# This would set the value of `DB_USER` to be `root`, unless `DB_USER` is defined elsewhere in which case it would use the value of that variable.
#
# ### Commands
#
# Shell commands can be evaluated via `$()`.
#
# NOTE: Commands are currently not supported on Windows.
#
# ```text
# DATE=$(date)
# ```
#
# ## File Precedence
#
# The default `.env` file defines _ALL_ ENV vars used within an application, with sane defaults.
# This file should be committed and should not contain any sensitive values.
#
# However in some cases you may need to define values to override those in `.env`,
# whether that be only for a single machine, or all machines in a specific environment.
#
# For these purposes there are other `.env` files that are loaded in a specific order to allow for just this use case:
#
# * `.env` - Defines all ENV vars, and their default values, used by the application.
# * `.env.local` - Overrides ENV vars for all environments, but only for the machine that contains the file.
#       This file should _NOT_ be committed, and is ignored in the `test` environment to ensure reproducibility.
# * `.env.<environment>` (e.g. `.env.test`) - Overrides ENV vars for only this one environment. These files _SHOULD_ be committed.
# * `.env.<environment>.local` (e.g. `.env.test.local`) - Machine-specific overrides, but only for a single environment. This file should _NOT_ be committed.
#
# See `#load_environment` for more information.
#
# NOTE: Real ENV vars always win against those created in any `.env` file.
#
# TIP: Environment specific `.env` files should _ONLY_ to override values defined within the default `.env` file and _NOT_ as a replacement to it.
# This ensures there is still a single source of truth and removes the need to duplicate everything for each environment.
#
# ## Production
#
# `.env` files are mainly intended for non-production environments in order to give the benefits of using ENV vars, but be more convenient/easier to use.
# They can of course continue to be used in production by distributing the base `.env` file along with the binary, then creating a `.env.local` on the production server and including production values within it.
# This can work quite well for simple applications, but ultimately a more robust solution that best leverages the features of the server the application is running on is best.
class Athena::Dotenv
  VERSION = "0.1.3"

  private VARNAME_REGEX = /(?i:_?[A-Z][A-Z0-9_]*+)/

  private enum State
    VARNAME
    VALUE
  end

  # Convenience method that loads one or more `.env` files, defaulting to `.env`.
  def self.load(path : String | ::Path = ".env", *paths : String | ::Path) : self
    instance = new
    instance.load path, *paths
    instance
  end

  @path : String | ::Path = ""
  @data = ""
  @values = Hash(String, String).new
  @reader : Char::Reader
  @line_number = 1

  def initialize(
    @env_key : String = "APP_ENV"
  )
    # Can't use a `getter!` macro since that would return a copy of the reader each time :/
    @reader = uninitialized Char::Reader
  end

  # Loads each `.env` file within the provided *paths*.
  #
  # ```
  # require "athena-dotenv"
  #
  # dotenv = Athena::Dotenv.new
  #
  # dotenv.load "./.env"
  # dotenv.load "./.env", "./.env.dev"
  # ```
  def load(*paths : String | ::Path) : Nil
    self.load false, paths
  end

  # Loads a `.env` file and its related additional files based on their [precedence][Athena::Dotenv--file-precedence] if they exist.
  #
  # The current ENV is determined by the value of `APP_ENV`, which is configurable globally via `.new`, or for a single load via the *env_key* parameter.
  # If no environment ENV var is defined, *default_environment* will be used.
  # The `.env.local` file will _NOT_ be loaded if the current environment is included within *test_environments*.
  #
  # Existing ENV vars may optionally be overridden by passing `true` to *override_existing_vars*.
  #
  # ```
  # require "athena-dotenv"
  #
  # dotenv = Athena::Dotenv.new
  #
  # # Use `APP_ENV`, or `dev`
  # dotenv.load_environment "./.env"
  #
  # # Custom *env_key* and *default_environment*
  # dotenv.load_environment "./.env", "ATHENA_ENV", "qa"
  # ```
  def load_environment(
    path : String | ::Path,
    env_key : String? = nil,
    default_environment : String = "dev",
    test_environments : Enumerable(String) = {"test"},
    override_existing_vars : Bool = false
  ) : Nil
    env_key = env_key || @env_key

    dist_path = "#{path}.dist"
    if File.file?(path) && !File.file?(dist_path)
      self.load override_existing_vars, {path}
    else
      self.load override_existing_vars, {dist_path}
    end

    # ameba:disable Lint/UselessAssign
    unless env = ENV[env_key]?
      self.populate({env_key => env = default_environment}, override_existing_vars)
    end

    local_path = "#{path}.local"
    if !test_environments.includes?(env) && File.file?(local_path)
      self.load override_existing_vars, {local_path}
      env = ENV.fetch env_key, env
    end

    return if "local" == env

    if File.file? p = "#{path}.#{env}"
      self.load override_existing_vars, {p}
    end

    if File.file? p = "#{path}.#{env}.local"
      self.load override_existing_vars, {p}
    end
  end

  # Same as `#load`, but will override existing ENV vars.
  def overload(*paths : String | ::Path) : Nil
    self.load true, paths
  end

  # Parses and returns a Hash based on the string contents of the provided *data* string.
  # The original `.env` file path may also be provided to *path* for more meaningful error messages.
  #
  # ```
  # require "athena-dotenv"
  #
  # path = "/path/to/.env"
  # dotenv = Athena::Dotenv.new
  #
  # File.write path, "FOO=BAR"
  #
  # dotenv.parse File.read(path), path # => {"FOO" => "BAR"}
  # ```
  def parse(data : String, path : String | ::Path = ".env") : Hash(String, String)
    @path = path
    @data = data = data.gsub("\r\n", "\n").gsub("\r", "\n")
    @reader = Char::Reader.new data

    @values.clear

    state : State = :varname
    name = ""

    self.skip_empty_lines

    while @reader.has_next?
      case state
      in .varname?
        name = self.lex_varname
        state = :value
      in .value?
        @values[name] = self.lex_value
        state = :varname
      end
    end

    if state.value?
      @values[name] = ""
    end

    begin
      @values.dup
    ensure
      @values.clear
      @reader = uninitialized Char::Reader
    end
  end

  # Populates the provides *values* into the environment.
  #
  # Existing ENV vars may optionally be overridden by passing `true` to *override_existing_vars*.
  #
  # ```
  # require "athena-dotenv"
  #
  # ENV["FOO"]? # => nil
  #
  # Athena::Dotenv.new.populate({"FOO" => "BAR"})
  #
  # ENV["FOO"]? # => "BAR"
  # ```
  def populate(values : Hash(String, String), override_existing_vars : Bool = false) : Nil
    update_loaded_vars = false

    loaded_vars = ENV.fetch("ATHENA_DOTENV_VARS", "").split(',').to_set

    values.each do |name, value|
      if !loaded_vars.includes?(name) && !override_existing_vars && ENV.has_key?(name)
        next
      end

      ENV[name] = value

      if !loaded_vars.includes?(name)
        loaded_vars << name
        update_loaded_vars = true
      end
    end

    if update_loaded_vars
      loaded_vars.delete ""
      ENV["ATHENA_DOTENV_VARS"] = loaded_vars.join ','
    end
  end

  private def advance_reader(string : String) : Nil
    @reader.pos += string.size
    @line_number += string.count '\n'
  end

  private def create_format_exception(message : String) : Athena::Dotenv::Exceptions::Format
    Athena::Dotenv::Exceptions::Format.new(
      message,
      Athena::Dotenv::Exceptions::Format::Context.new(
        @data,
        @path,
        @line_number,
        @reader.pos
      )
    )
  end

  private def lex_nested_expression : String
    char = @reader.next_char
    value = ""

    until char.in? '\n', ')'
      value += char

      if '(' == char
        value += "#{self.lex_nested_expression})"
      end

      char = @reader.next_char

      unless @reader.has_next?
        raise self.create_format_exception "Missing closing parenthesis"
      end
    end

    if '\n' == char
      raise self.create_format_exception "Missing closing parenthesis"
    end

    value
  end

  private def lex_varname : String
    unless match = /(export[ \t]++)?(#{VARNAME_REGEX})/.match(@data, @reader.pos, Regex::MatchOptions[:anchored])
      raise self.create_format_exception "Invalid character in variable name"
    end

    self.advance_reader match[0]

    if !@reader.has_next? || @reader.current_char.in? '\n', '#'
      raise self.create_format_exception "Unable to unset an environment variable" if match[1]?
      raise self.create_format_exception "Missing = in the environment variable declaration"
    end

    if @reader.current_char.whitespace?
      raise self.create_format_exception "Whitespace characters are not supported after the variable name"
    end

    if '=' != @reader.current_char
      raise self.create_format_exception "Missing = in the environment variable declaration"
    end

    @reader.pos += 1

    match[2]
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def lex_value : String
    if match = (/[ \t]*+(?:#.*)?$/m).match(@data, @reader.pos, Regex::MatchOptions[:anchored])
      self.advance_reader match[0]
      self.skip_empty_lines

      return ""
    end

    if @reader.current_char.whitespace?
      raise self.create_format_exception "Whitespace is not supported before the value"
    end

    loaded_vars = ENV.fetch("ATHENA_DOTENV_VARS", "").split(',').to_set
    loaded_vars.delete ""
    v = ""

    loop do
      case char = @reader.current_char
      when '\''
        len = 0

        loop do
          if @reader.pos + (len += 1) == @data.size
            @reader.pos += len

            raise self.create_format_exception "Missing quote to end the value"
          end

          break if @data[@reader.pos + len] == '\''
        end

        v += @data[1 + @reader.pos, len - 1]
        @reader.pos += 1 + len
      when '"'
        value = ""

        char = @reader.next_char

        unless @reader.has_next?
          raise self.create_format_exception "Missing quote to end the value"
        end

        while '"' != char || ('\\' == @data[@reader.pos - 1] && '\\' != @data[@reader.pos - 2])
          value += char

          char = @reader.next_char

          unless @reader.has_next?
            raise self.create_format_exception "Missing quote to end the value"
          end
        end

        @reader.next_char
        value = value.gsub(%(\\"), '"').gsub("\\r", "\r").gsub("\\n", "\n")
        resolved_value = value
        resolved_value = self.resolve_commands resolved_value, loaded_vars
        resolved_value = self.resolve_variables resolved_value, loaded_vars
        resolved_value = resolved_value.gsub "\\\\", "\\"

        v += resolved_value
      else
        value = ""
        previous_char = @reader.previous_char
        char = @reader.next_char
        while @reader.has_next? && !char.in?('\n', '"', '\'') && !((previous_char.in?(' ', '\t')) && '#' == char)
          if '\\' == char && @reader.has_next? && @reader.peek_next_char.in? '\'', '"'
            char = @reader.next_char
          end

          value += (previous_char = char)

          if '$' == char && @reader.has_next? && '(' == @reader.peek_next_char
            @reader.next_char
            value += "(#{self.lex_nested_expression})"
          end

          char = @reader.next_char
        end

        value = value.strip

        resolved_value = value
        resolved_value = self.resolve_commands resolved_value, loaded_vars
        resolved_value = self.resolve_variables resolved_value, loaded_vars
        resolved_value = resolved_value.gsub "\\\\", "\\"

        if resolved_value == value && value.each_char.any? &.whitespace?
          raise self.create_format_exception "A value containing spaces must be surrounded by quotes"
        end

        v += resolved_value

        if @reader.has_next? && '#' == char
          break
        end
      end

      break unless @reader.has_next? && @reader.current_char != '\n'
    end

    self.skip_empty_lines

    v
  end

  private def load(override_existing_vars : Bool, paths : Enumerable(String | ::Path)) : Nil
    paths.each do |path|
      if !File::Info.readable?(path) || File.directory?(path)
        raise Athena::Dotenv::Exceptions::Path.new path
      end

      self.populate(self.parse(File.read(path), path), override_existing_vars)
    end
  end

  private def resolve_commands(value : String, loaded_vars : Set(String)) : String
    return value unless value.includes? '$'

    regex = /
      (\\\\)?               # escaped with a backslash?
      \$
      (?<cmd>
          \(                # require opening parenthesis
          ([^()]|\g<cmd>)+  # allow any number of non-parens, or balanced parens (by nesting the <cmd> expression recursively)
          \)                # require closing paren
      )
    /x

    value.gsub regex do |_, match|
      if '\\' == match[1]?
        next match[0][1..]
      end

      {% if flag? :win32 %}
        # TODO: Support windows?
        raise RuntimeError.new "Resolving commands is not supported on Windows."
      {% end %}

      env = {} of String => String
      @values.each do |k, v|
        if loaded_vars.includes?(k) || !ENV.has_key?(k)
          env[k] = v
        end
      end

      output = IO::Memory.new
      error = IO::Memory.new

      status = Process.run(
        "echo #{match[0]}",
        shell: true,
        env: env,
        output: output,
        error: error
      )

      unless status.success?
        raise self.create_format_exception "Issue expanding a command (#{error})"
      end

      output.to_s.gsub /[\r\n]+$/, ""
    end
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def resolve_variables(value : String, loaded_vars : Set(String)) : String
    return value unless value.includes? '$'

    regex = /
      (?<!\\)
      (?P<backslashes>\\*)             # escaped with a backslash?
      \$
      (?!\()                           # no opening parenthesis
      (?P<opening_brace>\{)?           # optional brace
      (?P<name>(?i:[A-Z][A-Z0-9_]*+))? # var name
      (?P<default_value>:[-=][^\}]++)? # optional default value
      (?P<closing_brace>\})?           # optional closing brace
    /x

    value.gsub regex do |_, match|
      if match["backslashes"].size.odd?
        next match[0][1..]
      end

      # Unescaped $ not followed by var name
      if match["name"]?.nil?
        next match[0]
      end

      if "{" == match["opening_brace"]? && match["closing_brace"]?.nil?
        raise self.create_format_exception "Unclosed braces on variable expansion"
      end

      name = match["name"]

      value = if loaded_vars.includes?(name) && @values.has_key?(name)
                @values[name]
              elsif @values.has_key? name
                @values[name]
              else
                ENV.fetch name, ""
              end

      if value.empty? && (default_value = match["default_value"]?.presence)
        if unsupported_char = default_value.each_char.find &.in?('\'', '"', '{', '$')
          raise self.create_format_exception "Unsupported character '#{unsupported_char}' found in the default value of variable '$#{name}'"
        end

        value = match["default_value"][2..]

        if '=' == match["default_value"][1]
          @values[name] = value
        end
      end

      if !match["opening_brace"]?.presence && !match["closing_brace"]?.nil?
        value += '}'
      end

      "#{match["backslashes"]}#{value}"
    end
  end

  private def skip_empty_lines : Nil
    if match = (/(?:\s*+(?:#[^\n]*+)?+)++/).match(@data, @reader.pos, Regex::MatchOptions[:anchored])
      self.advance_reader match[0]
    end
  end
end
