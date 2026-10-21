require "../spec_helper"

struct UserPasswordHashCommandTest < ASPEC::TestCase
  @tester : ACON::Spec::CommandTester

  def initialize
    factory = APH::Factory.new({
      TestPasswordAuthenticatedUser => APH::Native.new(4),
      "Custom::Native::User"        => APH::Native.new(5),
      "Custom::Mock::User"          => MockPasswordHasher.new(hash: "mock_hash"),
    })

    @tester = ACON::Spec::CommandTester.new APH::Commands::UserPasswordHash.new(
      factory,
      ["TestPasswordAuthenticatedUser", "Custom::Native::User", "Custom::Mock::User"]
    )
  end

  def test_hash_password : Nil
    @tester.execute password: "password", "user-class": "Custom::Native::User", interactive: false

    @tester.assert_command_is_successful
    display = @tester.display
    display.should contain "Hasher used     Athena::PasswordHasher::Native"
    display.should contain "Self-salting hasher used: the hasher generated its own built-in salt."
    display.should contain "Password hashing succeeded"

    hash = display.match!(/Password hash   (\S+)/)[1]
    hash.should start_with "$2a$05$"
    APH::Native.new.verify(hash, "password").should be_true
  end

  def test_hash_password_output : Nil
    @tester.execute password: "p@ssw0rd", "user-class": "Custom::Mock::User", interactive: false

    @tester.display.should contain " Password hash   mock_hash"
  end

  def test_hash_no_password_no_interaction : Nil
    @tester.execute "user-class": "Custom::Native::User", interactive: false

    @tester.assert_command_is_not_successful
    @tester.display.should contain "[ERROR] The password must not be empty."
  end

  def test_hash_password_no_config_for_given_user_class : Nil
    expect_raises APH::Exception::Runtime, %(No password hasher has been configured for account "Foo::Bar::User".) do
      @tester.execute password: "password", "user-class": "Foo::Bar::User", interactive: false
    end
  end

  def test_hash_password_asks_non_provided_user_class : Nil
    @tester.inputs "Custom::Mock::User", "\n"
    @tester.execute password: "password", decorated: false

    @tester.display(true).should contain <<-TXT
       For which user class would you like to hash a password? [Custom::Mock::User]:
        [0] Custom::Mock::User
        [1] Custom::Native::User
        [2] TestPasswordAuthenticatedUser
      TXT

    @tester.display.should contain " Password hash   mock_hash"
  end

  def test_non_interactive_hash_password_uses_first_user_class : Nil
    @tester.execute password: "password", interactive: false

    @tester.display.should contain "Hasher used     Athena::PasswordHasher::Native"
    @tester.display.should contain "$2a$04$"
  end

  def test_warning_when_password_passed_as_argument_in_interactive_mode : Nil
    @tester.execute password: "secret", "user-class": "Custom::Mock::User", interactive: true

    @tester.display(true).gsub(/\s+/, " ").should contain "Passing the password as a command argument exposes it to shell history and the process list"
  end

  def test_no_warning_when_password_passed_as_argument_in_non_interactive_mode : Nil
    @tester.execute password: "secret", "user-class": "Custom::Mock::User", interactive: false

    @tester.display.should_not contain "Passing the password as a command argument"
  end

  def test_no_warning_when_password_read_interactively : Nil
    @tester.inputs "secret"
    @tester.execute "user-class": "Custom::Native::User", interactive: true

    @tester.assert_command_is_successful
    @tester.display.should contain "Type in your password to be hashed"
    @tester.display.should_not contain "Passing the password as a command argument"
    APH::Native.new.verify(@tester.display.match!(/Password hash   (\S+)/)[1], "secret").should be_true
  end

  def test_reads_password_from_stdin_when_password_is_dash_non_interactive : Nil
    @tester.inputs "secret"
    @tester.execute password: "-", "user-class": "Custom::Native::User", interactive: false

    @tester.assert_command_is_successful
    @tester.display.should_not contain "Passing the password as a command argument"
    APH::Native.new.verify(@tester.display.match!(/Password hash   (\S+)/)[1], "secret").should be_true
  end

  def test_reads_password_from_stdin_when_password_is_dash_interactive : Nil
    @tester.inputs "secret"
    @tester.execute password: "-", "user-class": "Custom::Native::User", interactive: true

    @tester.assert_command_is_successful
    @tester.display.should_not contain "Passing the password as a command argument"
    APH::Native.new.verify(@tester.display.match!(/Password hash   (\S+)/)[1], "secret").should be_true
  end

  def test_raises_on_no_configured_hashers : Nil
    tester = ACON::Spec::CommandTester.new APH::Commands::UserPasswordHash.new APH::Factory.new({} of String => APH::Interface)

    expect_raises APH::Exception::Runtime, "There are no configured password hashers." do
      tester.execute password: "password", interactive: false
    end
  end

  def test_completion_suggestions : Nil
    tester = ACON::Spec::CommandCompletionTester.new APH::Commands::UserPasswordHash.new(
      APH::Factory.new({} of String => APH::Interface),
      ["App::Entity::User", "App::Entity::Admin"]
    )

    tester.complete("p@ssw0rd", "").should eq ["App::Entity::User", "App::Entity::Admin"]
  end
end
