require "../spec_helper"

struct StringLineTest < ASPEC::TestCase
  @[DataProvider("tokenize_data")]
  def test_tokenize(input : String, tokens : Array(String)) : Nil
    input = ACON::Input::StringLine.new input
    input.@tokens.should eq tokens
  end

  def tokenize_data : Hash
    {
      "empty string"                                    => {"", [] of String},
      "arguments"                                       => {"foo", ["foo"]},
      "ignores whitespace between arguments"            => {"  foo  ", ["foo"]},
      "single quoted arguments"                         => {"'foo'", ["foo"]},
      "double quoted arguments"                         => {"\"foo\"", ["foo"]},
      "whitespace characters within string"             => {"'a\rb\nc\td'", ["a\rb\nc\td"]},
      "whitespace characters between args as spaces"    => {"'a'\r'b'\n'c'\t'd'", ["a", "b", "c", "d"]},
      "escaped double quoted arguments"                 => { %(\\"foo\\"), ["\"foo\""] },
      "escaped single quoted arguments"                 => { %(\\'foo\\'), ["'foo'"] },
      "short option"                                    => {"-a", ["-a"]},
      "aggregated short options"                        => {"-azc", ["-azc"]},
      "short option with value"                         => {"-awithavalue", ["-awithavalue"]},
      "short option with double quoted value"           => { %(-a"foo bar"), ["-afoo bar"] },
      "short option with multiple double quoted values" => { %(-a"foo bar""foo bar"), ["-afoo barfoo bar"] },
      "short option with single quoted value"           => { %(-a'foo bar'), ["-afoo bar"] },
      "short option with multiple single quoted values" => { %(-a'foo bar''foo bar'), ["-afoo barfoo bar"] },
      "long option"                                     => {"--long-option", ["--long-option"]},
      "long option with value"                          => {"--long-option=foo", ["--long-option=foo"]},
      "long option with double quoted value"            => { %(--long-option="foo bar"), ["--long-option=foo bar"] },
      "long option with multiple double quoted values"  => { %(--long-option="foo bar""another"), ["--long-option=foo baranother"] },
      "long option with single quoted value"            => { %(--long-option='foo bar'), ["--long-option=foo bar"] },
      "long option with multiple single quoted values"  => { %(--long-option='foo bar''another'), ["--long-option=foo baranother"] },
      "several arguments and options"                   => {"foo -a -ffoo --long bar", ["foo", "-a", "-ffoo", "--long", "bar"]},
      "quoted quotes"                                   => {"--arg=\\\"'Jenny'\\''s'\\\"", ["--arg=\"Jenny's\""]},
    }
  end
end
