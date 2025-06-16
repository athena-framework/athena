require "spec"

require "../src/athena-console"
require "../src/spec"

require "athena-spec"
require "athena-clock/spec"

require "./fixtures/commands/io"
require "./fixtures/**"

# Spec by default disables colorize with `TERM=dumb`.
# Override that given there are specs based on ansi output.
Colorize.enabled = true

struct MockCommandLoader
  include Athena::Console::Loader::Interface

  def initialize(
    *,
    @command_or_exception : ACON::Command | ::Exception? = nil,
    @has : Bool = true,
    @names : Array(String) | ::Exception = [] of String,
  )
  end

  def get(name : String) : ACON::Command
    case v = @command_or_exception
    in ::Exception   then raise v
    in ACON::Command then v
    in Nil           then raise "BUG: no command or exception was set"
    end
  end

  def has?(name : String) : Bool
    @has
  end

  def names : Array(String)
    case v = @names
    in ::Exception   then raise v
    in Array(String) then v
    end
  end
end

def with_isolated_env(&) : Nil
  old_values = ENV.to_h

  begin
    ENV.clear

    yield
  ensure
    ENV.clear
    old_values.each do |key, old_value|
      ENV[key] = old_value
    end
  end
end

ASPEC.run_all
