require "./spec_helper"

struct DotEnvTest < ASPEC::TestCase
  def initialize
    ENV.clear
  end

  @[DataProvider("env_data")]
  def test_parse(data : String, expected : Hash(String, String)) : Nil
    ENV["LOCAL"] = "local"
    ENV["REMOTE"] = "remote"

    Athena::Dotenv.new.parse(data).should eq expected
  end

  def env_data : Array
    tests = [
      # Backslashes
      {"FOO=foo\\\\bar", {"FOO" => "foo\\bar"}},
      {"FOO='foo\\\\bar'", {"FOO" => "foo\\\\bar"}},
      {"FOO=\"foo\\\\bar\"", {"FOO" => "foo\\bar"}},

      # Escaped backslash in front of variable
      {"BAR=bar\nFOO=foo\\\\$BAR", {"BAR" => "bar", "FOO" => "foo\\bar"}},
      {"BAR=bar\nFOO='foo\\\\$BAR'", {"BAR" => "bar", "FOO" => "foo\\\\$BAR"}},
      {"BAR=bar\nFOO=\"foo\\\\$BAR\"", {"BAR" => "bar", "FOO" => "foo\\bar"}},

      {"FOO=foo\\\\\\$BAR", {"FOO" => "foo\\$BAR"}},
      {"FOO='foo\\\\\\$BAR'", {"FOO" => "foo\\\\\\$BAR"}},
      {"FOO=\"foo\\\\\\$BAR\"", {"FOO" => "foo\\$BAR"}},

      # Spaces
      {"FOO=bar", {"FOO" => "bar"}},
      {" FOO=bar ", {"FOO" => "bar"}},
      {"FOO=", {"FOO" => ""}},
      {"FOO=\n\n\nBAR=bar", {"FOO" => "", "BAR" => "bar"}},
      {"FOO=  ", {"FOO" => ""}},
      {"FOO=\nBAR=bar", {"FOO" => "", "BAR" => "bar"}},

      # Newlines
      {"\n\nFOO=bar\r\n\n", {"FOO" => "bar"}},
      {"FOO=bar\r\nBAR=foo", {"FOO" => "bar", "BAR" => "foo"}},
      {"FOO=bar\rBAR=foo", {"FOO" => "bar", "BAR" => "foo"}},
      {"FOO=bar\nBAR=foo", {"FOO" => "bar", "BAR" => "foo"}},

      # Quotes
      {"FOO=\"bar\"\n", {"FOO" => "bar"}},
      {"FOO=\"bar'foo\"\n", {"FOO" => "bar'foo"}},
      {"FOO='bar'\n", {"FOO" => "bar"}},
      {"FOO='bar\"foo'\n", {"FOO" => "bar\"foo"}},
      {"FOO=\"bar\\\"foo\"\n", {"FOO" => "bar\"foo"}},
      {"FOO=\"bar\nfoo\"", {"FOO" => "bar\nfoo"}},
      {"FOO=\"bar\\rfoo\"", {"FOO" => "bar\rfoo"}}, # Double quote expands to real `\r`
      {"FOO='bar\nfoo'", {"FOO" => "bar\nfoo"}},
      {"FOO='bar\\rfoo'", {"FOO" => "bar\\rfoo"}}, # Single quotes keep the literal `\r`
      {"FOO='bar\nfoo'", {"FOO" => "bar\nfoo"}},
      {"FOO=\" FOO \"", {"FOO" => " FOO "}},
      {"FOO=\"  \"", {"FOO" => "  "}},
      {"PATH=\"c:\\\\\"", {"PATH" => "c:\\"}},
      {"FOO=\"bar\nfoo\"", {"FOO" => "bar\nfoo"}},
      {"FOO=BAR\\\"", {"FOO" => "BAR\""}},
      {"FOO=BAR\\'BAZ", {"FOO" => "BAR'BAZ"}},
      {"FOO=\\\"BAR", {"FOO" => "\"BAR"}},

      # Concatenated values
      {"FOO='bar''foo'\n", {"FOO" => "barfoo"}},
      {"FOO='bar '' baz'", {"FOO" => "bar  baz"}},
      {"FOO=bar\nBAR='baz'\"$FOO\"", {"FOO" => "bar", "BAR" => "bazbar"}},
      {"FOO='bar '\\'' baz'", {"FOO" => "bar ' baz"}},

      # Comments
      {"#FOO=bar\nBAR=foo", {"BAR" => "foo"}},
      {"#FOO=bar # Comment\nBAR=foo", {"BAR" => "foo"}},
      {"FOO='bar foo' # Comment", {"FOO" => "bar foo"}},
      {"FOO='bar#foo' # Comment", {"FOO" => "bar#foo"}},
      {"# Comment\r\nFOO=bar\n# Comment\nBAR=foo", {"FOO" => "bar", "BAR" => "foo"}},
      {"FOO=bar # Another comment\nBAR=foo", {"FOO" => "bar", "BAR" => "foo"}},
      {"FOO=\n\n# comment\nBAR=bar", {"FOO" => "", "BAR" => "bar"}},
      {"FOO=NOT#COMMENT", {"FOO" => "NOT#COMMENT"}},
      {"FOO=  # Comment", {"FOO" => ""}},

      # Edge cases - no conversions, only strings as values
      {"FOO=0", {"FOO" => "0"}},
      {"FOO=false", {"FOO" => "false"}},
      {"FOO=null", {"FOO" => "null"}},

      # Export
      {"export FOO=bar", {"FOO" => "bar"}},
      {"  export   FOO=bar", {"FOO" => "bar"}},

      # Variable expansion
      {"FOO=BAR\nBAR=$FOO", {"FOO" => "BAR", "BAR" => "BAR"}},
      {"FOO=BAR\nBAR=\"$FOO\"", {"FOO" => "BAR", "BAR" => "BAR"}},
      {"FOO=BAR\nBAR='$FOO'", {"FOO" => "BAR", "BAR" => "$FOO"}},
      {"FOO_BAR9=BAR\nBAR=$FOO_BAR9", {"FOO_BAR9" => "BAR", "BAR" => "BAR"}},
      {"FOO=BAR\nBAR=${FOO}Z", {"FOO" => "BAR", "BAR" => "BARZ"}},
      {"FOO=BAR\nBAR=$FOO}", {"FOO" => "BAR", "BAR" => "BAR}"}},
      {"FOO=BAR\nBAR=\\$FOO", {"FOO" => "BAR", "BAR" => "$FOO"}},
      {"FOO=\" \\$ \"", {"FOO" => " $ "}},
      {"FOO=\" $ \"", {"FOO" => " $ "}},
      {"BAR=$LOCAL", {"BAR" => "local"}},
      {"BAR=$REMOTE", {"BAR" => "remote"}},
      {"FOO=$NOTDEFINED", {"FOO" => ""}},
      {"FOO=BAR\nBAR=${FOO:-TEST}", {"FOO" => "BAR", "BAR" => "BAR"}},
      {"FOO=BAR\nBAR=${NOTDEFINED:-TEST}", {"FOO" => "BAR", "BAR" => "TEST"}},
      {"FOO=\nBAR=${FOO:-TEST}", {"FOO" => "", "BAR" => "TEST"}},
      {"FOO=\nBAR=$FOO:-TEST}", {"FOO" => "", "BAR" => "TEST}"}},
      {"FOO=BAR\nBAR=${FOO:=TEST}", {"FOO" => "BAR", "BAR" => "BAR"}},
      {"FOO=BAR\nBAR=${NOTDEFINED:=TEST}", {"FOO" => "BAR", "NOTDEFINED" => "TEST", "BAR" => "TEST"}},
      {"FOO=\nBAR=${FOO:=TEST}", {"FOO" => "TEST", "BAR" => "TEST"}},
      {"FOO=\nBAR=$FOO:=TEST}", {"FOO" => "TEST", "BAR" => "TEST}"}},
      {"FOO=foo\nFOOBAR=${FOO}${BAR}", {"FOO" => "foo", "FOOBAR" => "foo"}},

      # Underscores
      {"_FOO=BAR", {"_FOO" => "BAR"}},
      {"_FOO_BAR=FOOBAR", {"_FOO_BAR" => "FOOBAR"}},
    ] of {String, Hash(String, String)}

    {% if flag? :unix %}
      tests.push(
        {"FOO=$(echo foo)", {"FOO" => "foo"}},
        {"FOO=$((1+2))", {"FOO" => "3"}},
        {"FOO=FOO$((1+2))BAR", {"FOO" => "FOO3BAR"}},
        {"FOO=$(echo \"$(echo \"$(echo \"$(echo foo)\")\")\")", {"FOO" => "foo"}},
        {"FOO=$(echo \"Quotes won't be a problem\")", {"FOO" => "Quotes won't be a problem"}},
        {"FOO=bar\nBAR=$(echo \"FOO is $FOO\")", {"FOO" => "bar", "BAR" => "FOO is bar"}},
      )
    {% end %}

    tests
  end

  @[DataProvider("env_data_with_format_errors")]
  def test_parse_with_format_error(data : String, error_message : String | Regex) : Nil
    dotenv = Athena::Dotenv.new

    expect_raises Athena::Dotenv::Exception::Format, error_message do
      dotenv.parse data
    end
  end

  def env_data_with_format_errors : Array
    tests = [
      {"FOO=BAR BAZ", "A value containing spaces must be surrounded by quotes in '.env' at line 1.\n...FOO=BAR BAZ...\n             ^ line 1 offset 11"},
      {"FOO BAR=BAR", "Whitespace characters are not supported after the variable name in '.env' at line 1.\n...FOO BAR=BAR...\n     ^ line 1 offset 3"},
      {"FOO", "Missing = in the environment variable declaration in '.env' at line 1.\n...FOO...\n     ^ line 1 offset 3"},
      {"FOO=\"foo", "Missing quote to end the value in '.env' at line 1.\n...FOO=\"foo...\n          ^ line 1 offset 8"},
      {"FOO='foo", "Missing quote to end the value in '.env' at line 1.\n...FOO='foo...\n          ^ line 1 offset 8"},
      {"FOO=\"foo\nBAR=\"bar\"", "Missing quote to end the value in '.env' at line 1.\n...FOO=\"foo\\nBAR=\"bar\"...\n                     ^ line 1 offset 18"},
      {"FOO='foo\n", "Missing quote to end the value in '.env' at line 1.\n...FOO='foo\\n...\n            ^ line 1 offset 9"},
      {"export FOO", "Unable to unset an environment variable in '.env' at line 1.\n...export FOO...\n            ^ line 1 offset 10"},
      {"FOO=${FOO", "Unclosed braces on variable expansion in '.env' at line 1.\n...FOO=${FOO...\n           ^ line 1 offset 9"},
      {"FOO= BAR", "Whitespace is not supported before the value in '.env' at line 1.\n...FOO= BAR...\n      ^ line 1 offset 4"},
      {"Стасян", "Invalid character in variable name in '.env' at line 1.\n...Стасян...\n  ^ line 1 offset 0"},
      {"FOO!", "Missing = in the environment variable declaration in '.env' at line 1.\n...FOO!...\n     ^ line 1 offset 3"},
      {"FOO=$(echo foo", "Missing closing parenthesis in '.env' at line 1.\n...FOO=$(echo foo...\n                ^ line 1 offset 14"},
      {"FOO=$(echo foo\n", "Missing closing parenthesis in '.env' at line 1.\n...FOO=$(echo foo\\n...\n                ^ line 1 offset 14"},
      {"FOO=\nBAR=${FOO:-\\'a{a}a}", "Unsupported character ''' found in the default value of variable '$FOO' in '.env' at line 2.\n...\\nBAR=${FOO:-\\'a{a}a}...\n                       ^ line 2 offset 24"},
      {"FOO=\nBAR=${FOO:-a$a}", "Unsupported character '$' found in the default value of variable '$FOO' in '.env' at line 2.\n...FOO=\\nBAR=${FOO:-a$a}...\n                       ^ line 2 offset 20"},
      {"FOO=\nBAR=${FOO:-a\"a}", "Unclosed braces on variable expansion in '.env' at line 2.\n...FOO=\\nBAR=${FOO:-a\"a}...\n                    ^ line 2 offset 17"},
      {"_=FOO", "Invalid character in variable name in '.env' at line 1.\n..._=FOO...\n  ^ line 1 offset 0"},
    ] of {String, String | Regex}

    {% if flag? :unix %}
      tests << {"FOO=$((1dd2))", /Issue expanding a command \(.*\n\) in '\.env' at line 1\.\n\.\.\.FOO=\$\(\(1dd2\)\)\.\.\.\n               \^ line 1 offset 13/}
    {% end %}

    tests
  end

  def test_load : Nil
    ENV.delete "FOO"
    ENV.delete "BAR"

    file1 = File.tempfile do |f|
      f.puts "FOO=BAR"
    end

    file2 = File.tempfile do |f|
      f.puts "BAR=BAZ"
    end

    Athena::Dotenv.new.load file1.path, file2.path

    ENV["FOO"]?.should eq "BAR"
    ENV["BAR"]?.should eq "BAZ"

    ENV.delete "FOO"
    ENV.delete "BAR"

    file1.delete
    file2.delete
  end

  def test_class_load : Nil
    ENV.delete "FOO"
    ENV.delete "BAR"

    file1 = File.tempfile do |f|
      f.puts "FOO=BAR"
    end

    file2 = File.tempfile do |f|
      f.puts "BAR=BAZ"
    end

    Athena::Dotenv.load file1.path, file2.path

    ENV["FOO"]?.should eq "BAR"
    ENV["BAR"]?.should eq "BAZ"

    ENV.delete "FOO"
    ENV.delete "BAR"

    file1.delete
    file2.delete
  end

  def test_class_load_single_file : Nil
    ENV.delete "FOO"

    file = File.tempfile do |f|
      f.puts "FOO=BAR"
    end

    Athena::Dotenv.load file.path

    ENV["FOO"]?.should eq "BAR"

    ENV.delete "FOO"

    file.delete
  end

  def test_class_load_defaults : Nil
    ENV.delete "BAZ"

    file = File.open ".env", "w"
    file.puts "BAZ=BAZ"
    file.flush

    Athena::Dotenv.load

    ENV["BAZ"]?.should eq "BAZ"

    ENV.delete "BAZ"

    file.delete
  end

  def test_load_environment : Nil
    reset_context = Proc(Nil).new do
      ENV.delete "ATHENA_DOTENV_VARS"
      ENV.delete "FOO"
      ENV.delete "TEST_APP_ENV"

      ENV["EXISTING_KEY"] = "EXISTING_VALUE"
    end

    path = File.tempname

    # .env
    reset_context.call
    File.write path, "FOO=BAR\nEXISTING_KEY=NEW_VALUE"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "BAR"
    ENV["TEST_APP_ENV"]?.should eq "dev"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "BAR"
    ENV["TEST_APP_ENV"]?.should eq "dev"
    ENV["EXISTING_KEY"]?.should eq "NEW_VALUE"

    # .env.local
    reset_context.call
    ENV["TEST_APP_ENV"] = "local"
    File.write "#{path}.local", "FOO=localBAR\nEXISTING_KEY=localNEW_VALUE"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "localBAR"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call
    ENV["TEST_APP_ENV"] = "local"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "localBAR"
    ENV["EXISTING_KEY"]?.should eq "localNEW_VALUE"

    # Special case for test
    reset_context.call
    ENV["TEST_APP_ENV"] = "test"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "BAR"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call
    ENV["TEST_APP_ENV"] = "test"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "BAR"
    ENV["EXISTING_KEY"]?.should eq "NEW_VALUE"

    # .env.dev
    reset_context.call
    File.write "#{path}.dev", "FOO=devBAR\nEXISTING_KEY=devNEW_VALUE"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "devBAR"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "devBAR"
    ENV["EXISTING_KEY"]?.should eq "devNEW_VALUE"

    # .env.dev.local
    reset_context.call
    File.write "#{path}.dev.local", "FOO=devlocalBAR\nEXISTING_KEY=devlocalNEW_VALUE"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "devlocalBAR"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "devlocalBAR"
    ENV["EXISTING_KEY"]?.should eq "devlocalNEW_VALUE"

    File.delete? "#{path}.local"
    File.delete? "#{path}.dev"
    File.delete? "#{path}.dev.local"

    # .env.dist
    reset_context.call
    File.write "#{path}.dist", "FOO=distBAR\nEXISTING_KEY=distNEW_VALUE"

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV"
    ENV["FOO"]?.should eq "distBAR"
    ENV["EXISTING_KEY"]?.should eq "EXISTING_VALUE"

    reset_context.call

    Athena::Dotenv.new.load_environment path, "TEST_APP_ENV", override_existing_vars: true
    ENV["FOO"]?.should eq "distBAR"
    ENV["EXISTING_KEY"]?.should eq "distNEW_VALUE"

    File.delete "#{path}.dist"

    reset_context.call
    ENV.delete "EXISTING_KEY"

    File.delete? path
  end

  def test_overload : Nil
    ENV.delete "FOO"
    ENV.delete "BAR"

    ENV["FOO"] = "initial_foo_value"
    ENV["BAR"] = "initial_bar_value"

    file1 = File.tempfile do |f|
      f.puts "FOO=BAR"
    end

    file2 = File.tempfile do |f|
      f.puts "BAR=BAZ"
    end

    Athena::Dotenv.new.overload file1.path, file2.path

    ENV["FOO"]?.should eq "BAR"
    ENV["BAR"]?.should eq "BAZ"

    ENV.delete "FOO"
    ENV.delete "BAR"

    file1.delete
    file2.delete
  end

  def test_load_directory : Nil
    expect_raises Athena::Dotenv::Exception::Path do
      Athena::Dotenv.new.load __DIR__
    end
  end

  def test_does_not_override_by_default : Nil
    ENV["TEST_ENV_VAR"] = "original_value"

    Athena::Dotenv.new.populate({"TEST_ENV_VAR" => "new_value"})

    ENV["TEST_ENV_VAR"]?.should eq "original_value"

    ENV.delete "TEST_ENV_VAR"
  end

  def test_allows_override : Nil
    ENV["TEST_ENV_VAR"] = "original_value"

    Athena::Dotenv.new.populate({"TEST_ENV_VAR" => "new_value"}, true)

    ENV["TEST_ENV_VAR"]?.should eq "new_value"

    ENV.delete "TEST_ENV_VAR"
  end

  def test_memorizing_loaded_var_names_in_special_variable : Nil
    # Does not already exist
    ENV.delete "ATHENA_DOTENV_VARS"

    ENV.delete "APP_DEBUG"
    ENV.delete "FOO"

    Athena::Dotenv.new.populate({"APP_DEBUG" => "1", "FOO" => "BAR"})

    ENV["ATHENA_DOTENV_VARS"]?.should eq "APP_DEBUG,FOO"

    # Already exists
    ENV["ATHENA_DOTENV_VARS"] = "APP_ENV"

    ENV["APP_DEBUG"] = "1"
    ENV.delete "FOO"

    dotenv = Athena::Dotenv.new
    dotenv.populate({"APP_DEBUG" => "0", "FOO" => "BAR"})
    dotenv.populate({"FOO" => "BAZ"})

    ENV["ATHENA_DOTENV_VARS"]?.should eq "APP_ENV,FOO"
  end

  def test_overriding_env_vars_with_names_memorized_in_special_variable : Nil
    ENV["ATHENA_DOTENV_VARS"] = "FOO,BAR,BAZ"

    ENV["FOO"] = "foo"
    ENV["BAR"] = "bar"
    ENV["BAZ"] = "bar"
    ENV["DOCUMENT_ROOT"] = "/var/www"

    Athena::Dotenv.new.populate({
      "FOO"           => "foo1",
      "BAR"           => "bar1",
      "BAZ"           => "baz1",
      "DOCUMENT_ROOT" => "/boot",
    })

    ENV["FOO"]?.should eq "foo1"
    ENV["BAR"]?.should eq "bar1"
    ENV["BAZ"]?.should eq "baz1"
    ENV["DOCUMENT_ROOT"]?.should eq "/var/www"
  end
end
