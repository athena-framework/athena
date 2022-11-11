require "../spec_helper"

struct OutputFormatterTest < ASPEC::TestCase
  @formatter : ACON::Formatter::Output

  def initialize
    @formatter = ACON::Formatter::Output.new true
  end

  def test_format_empty_tag : Nil
    @formatter.format("foo<>bar").should eq "foo<>bar"
  end

  def test_format_lg_char_escaping : Nil
    @formatter.format("foo\\<bar").should eq "foo<bar"
    @formatter.format("foo << bar").should eq "foo << bar"
    @formatter.format("foo << bar \\").should eq "foo << bar \\"
    @formatter.format("foo << <info>bar \\ baz</info> \\").should eq "foo << \e[32mbar \\ baz\e[0m \\"
    @formatter.format("\\<info>some info\\</info>").should eq "<info>some info</info>"
    ACON::Formatter::Output.escape("<info>some info</info>").should eq "\\<info>some info\\</info>"

    @formatter.format("<comment>Some\\Path\\ToFile does work very well!</comment>").should eq "\e[33mSome\\Path\\ToFile does work very well!\e[0m"
  end

  def test_format_built_in_styles : Nil
    @formatter.has_style?("error").should be_true
    @formatter.has_style?("info").should be_true
    @formatter.has_style?("comment").should be_true
    @formatter.has_style?("question").should be_true

    @formatter.format("<error>some error</error>").should eq "\e[97;41msome error\e[0m"
    @formatter.format("<info>some info</info>").should eq "\e[32msome info\e[0m"
    @formatter.format("<comment>some comment</comment>").should eq "\e[33msome comment\e[0m"
    @formatter.format("<question>some question</question>").should eq "\e[30;46msome question\e[0m"
  end

  # TODO: Dependent on https://github.com/crystal-lang/crystal/issues/10652.
  def ptest_format_nested_styles : Nil
    @formatter.format("<error>some <info>some info</info> error</error>").should eq "\e[97;41msome \e[0m\e[32msome info\e[39m\e[97;41m error\e[0m"
  end

  # TODO: Dependent on https://github.com/crystal-lang/crystal/issues/10652.
  def ptest_format_deeply_nested_styles : Nil
    @formatter.format("<error>error<info>info<comment>comment</info>error</error>").should eq "\e[97;41merror\e[0m\e[32minfo\e[39m\e[33mcomment\e[39m\e[97;41merror\e[0m"
  end

  def test_format_adjacent_styles : Nil
    @formatter.format("<error>some error</error><info>some info</info>").should eq "\e[97;41msome error\e[0m\e[32msome info\e[0m"
  end

  def test_format_adjacent_styles_not_greedy : Nil
    @formatter.format("(<info>>=2.0,<2.3</info>)").should eq "(\e[32m>=2.0,<2.3\e[0m)"
  end

  def test_format_style_escaping : Nil
    @formatter.format(%((<info>#{@formatter.class.escape "z>=2.0,<\\<<a2.3\\"}</info>))).should eq "(\e[32mz>=2.0,<<<a2.3\\\e[0m)"
    @formatter.format(%(<info>#{@formatter.class.escape "<error>some error</error>"}</info>)).should eq "\e[32m<error>some error</error>\e[0m"
  end

  def test_format_custom_style : Nil
    style = ACON::Formatter::OutputStyle.new :blue, :white
    @formatter.set_style "test", style

    @formatter.style("test").should eq style
    @formatter.style("info").should_not eq style

    style = ACON::Formatter::OutputStyle.new :blue, :white
    @formatter.set_style "b", style

    @formatter.format("<test>some message</test><b>custom</b>").should eq "\e[34;107msome message\e[0m\e[34;107mcustom\e[0m"
    # TODO: Also assert it works when nested.
  end

  def test_format_redefine_style : Nil
    style = ACON::Formatter::OutputStyle.new :blue, :white
    @formatter.set_style "info", style

    @formatter.format("<info>some custom message</info>").should eq "\e[34;107msome custom message\e[0m"
  end

  def test_format_inline_style : Nil
    @formatter.format("<fg=blue;bg=red>some text</>").should eq "\e[34;41msome text\e[0m"
    @formatter.format("<fg=blue;bg=red>some text</fg=blue;bg=red>").should eq "\e[34;41msome text\e[0m"
  end

  @[DataProvider("inline_style_options_provider")]
  def test_format_inline_style_options(tag : String, expected : String?, input : String?, truecolor : Bool) : Nil
    if truecolor && "truecolor" != ENV["COLORTERM"]?
      pending! "The terminal does not support true colors."
    end

    style_string = tag.strip "<>"

    style = @formatter.create_style_from_string style_string

    if expected.nil?
      style.should be_nil
      expected = "#{tag}#{input}</#{style_string}>"
      @formatter.format(expected).should eq expected
    else
      style.should be_a ACON::Formatter::OutputStyle
      @formatter.format("#{tag}#{input}</>").should eq expected
      @formatter.format("#{tag}#{input}</#{style_string}>").should eq expected
    end
  end

  def inline_style_options_provider : Tuple
    {
      {"<unknown=_unknown_>", nil, nil, false},
      {"<unknown=_unknown_;a=1;b>", nil, nil, false},
      {"<fg=green;>", "\e[32m[test]\e[0m", "[test]", false},
      {"<fg=green;bg=blue;>", "\e[32;44ma\e[0m", "a", false},
      {"<fg=green;options=bold>", "\e[32;1mb\e[0m", "b", false},
      {"<fg=green;options=reverse;>", "\e[32;7m<a>\e[0m", "<a>", false},
      {"<fg=green;options=bold,underline>", "\e[32;1;4mz\e[0m", "z", false},
      {"<fg=green;options=bold,underline,reverse;>", "\e[32;1;4;7md\e[0m", "d", false},
      {"<fg=#00ff00;bg=#0000ff>", "\e[38;2;0;255;0;48;2;0;0;255m[test]\e[0m", "[test]", true},
    }
  end

  def test_format_non_style_tag : Nil
    @formatter
      .format("<info>some <tag> <setting=value> styled <p>single-char tag</p></info>")
      .should eq "\e[32msome \e[0m\e[32m<tag>\e[0m\e[32m \e[0m\e[32m<setting=value>\e[0m\e[32m styled \e[0m\e[32m<p>\e[0m\e[32msingle-char tag\e[0m\e[32m</p>\e[0m"
  end

  def test_format_long_string : Nil
    long = "\\" * 14_000
    @formatter.format("<error>some error</error>#{long}").should eq "\e[97;41msome error\e[0m#{long}"
  end

  def test_has_style : Nil
    @formatter = ACON::Formatter::Output.new

    @formatter.has_style?("error").should be_true
    @formatter.has_style?("info").should be_true
    @formatter.has_style?("comment").should be_true
    @formatter.has_style?("question").should be_true
  end

  @[DataProvider("decorated_and_non_decorated_output")]
  def test_format_not_decorated(input : String, expected_non_decorated_output : String, expected_decorated_output : String, term_emulator : String) : Nil
    previous_term_emulator = ENV["TERMINAL_EMULATOR"]?
    ENV["TERMINAL_EMULATOR"] = term_emulator

    begin
      ACON::Formatter::Output.new(true).format(input).should eq expected_decorated_output
      ACON::Formatter::Output.new(false).format(input).should eq expected_non_decorated_output
    ensure
      if previous_term_emulator
        ENV["TERMINAL_EMULATOR"] = previous_term_emulator
      else
        ENV.delete "TERMINAL_EMULATOR"
      end
    end
  end

  def decorated_and_non_decorated_output : Tuple
    {
      {"<error>some error</error>", "some error", "\e[97;41msome error\e[0m", "foo"},
      {"<info>some info</info>", "some info", "\e[32msome info\e[0m", "foo"},
      {"<comment>some comment</comment>", "some comment", "\e[33msome comment\e[0m", "foo"},
      {"<question>some question</question>", "some question", "\e[30;46msome question\e[0m", "foo"},
      {"<fg=red>some text with inline style</>", "some text with inline style", "\e[31msome text with inline style\e[0m", "foo"},
      {"<href=idea://open/?file=/path/SomeFile.php&line=12>some URL</>", "some URL", "\e]8;;idea://open/?file=/path/SomeFile.php&line=12\e\\some URL\e]8;;\e\\", "foo"},
      {"<href=idea://open/?file=/path/SomeFile.php&line=12>some URL</>", "some URL", "some URL", "JetBrains-JediTerm"},
    }
  end

  def test_format_with_line_breaks : Nil
    @formatter.format("<info>\nsome text</info>").should eq "\e[32m\nsome text\e[0m"
    @formatter.format("<info>some text\n</info>").should eq "\e[32msome text\n\e[0m"
    @formatter.format("<info>\nsome text\n</info>").should eq "\e[32m\nsome text\n\e[0m"
    @formatter.format("<info>\nsome text\nmore text\n</info>").should eq "\e[32m\nsome text\nmore text\n\e[0m"
  end

  def test_format_and_wrap : Nil
    @formatter.format_and_wrap("ooo<error>bar</error> bbz", 2).should eq "oo\no\e[97;41mb\e[0m\n\e[97;41mar\e[0m\nbb\nz"
    @formatter.format_and_wrap("pre <error>foo bar baz</error> post", 2).should eq "pr\ne \e[97;41m\e[0m\n\e[97;41mfo\e[0m\n\e[97;41mo \e[0m\n\e[97;41mba\e[0m\n\e[97;41mr \e[0m\n\e[97;41mba\e[0m\n\e[97;41mz\e[0m \npo\nst"
    @formatter.format_and_wrap("pre <error>foo bar baz</error> post", 3).should eq "pre\e[97;41m\e[0m\n\e[97;41mfoo\e[0m\n\e[97;41mbar\e[0m\n\e[97;41mbaz\e[0m\npos\nt"
    @formatter.format_and_wrap("pre <error>foo bar baz</error> post", 4).should eq "pre \e[97;41m\e[0m\n\e[97;41mfoo \e[0m\n\e[97;41mbar \e[0m\n\e[97;41mbaz\e[0m \npost"
    @formatter.format_and_wrap("pre <error>foo bbr baz</error> post", 5).should eq "pre \e[97;41mf\e[0m\n\e[97;41moo bb\e[0m\n\e[97;41mr baz\e[0m\npost"

    @formatter.format_and_wrap("Lorem <error>ipsum</error> dolor <info>sit</info> amet", 4).should eq "Lore\nm \e[97;41mip\e[0m\n\e[97;41msum\e[0m \ndolo\nr \e[32msi\e[0m\n\e[32mt\e[0m am\net"
    @formatter.format_and_wrap("Lorem <error>ipsum</error> dolor <info>sit</info> amet", 8).should eq "Lorem \e[97;41mip\e[0m\n\e[97;41msum\e[0m dolo\nr \e[32msit\e[0m am\net"
    @formatter.format_and_wrap("Lorem <error>ipsum</error> dolor <info>sit</info>, <error>amet</error> et <info>laudantium</info> architecto", 18).should eq "Lorem \e[97;41mipsum\e[0m dolor \e[32m\e[0m\n\e[32msit\e[0m, \e[97;41mamet\e[0m et \e[32mlauda\e[0m\n\e[32mntium\e[0m architecto"
  end

  def test_format_and_wrap_non_decorated : Nil
    @formatter = ACON::Formatter::Output.new

    @formatter.format_and_wrap("ooo<error>bar</error> baz", 2).should eq "oo\nob\nar\nba\nz"
    @formatter.format_and_wrap("pre <error>foo bbr baz</error> post", 2).should eq "pr\ne \nfo\no \nbb\nr \nba\nz \npo\nst"
    @formatter.format_and_wrap("pre <error>foo bar baz</error> post", 3).should eq "pre\nfoo\nbar\nbaz\npos\nt"
    @formatter.format_and_wrap("pre <error>foo bar baz</error> post", 4).should eq "pre \nfoo \nbar \nbaz \npost"
    @formatter.format_and_wrap("pre <error>foo bbr baz</error> post", 5).should eq "pre f\noo bb\nr baz\npost"

    @formatter.format_and_wrap(nil, 5).should eq ""

    @formatter.format_and_wrap("And Then There Were None", 15).should eq "And Then There \nWere None"
  end
end
