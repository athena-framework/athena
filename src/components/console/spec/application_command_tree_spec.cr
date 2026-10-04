require "./spec_helper"

private class ProgramNameTreeApplication < ACON::Application
  protected def program_name : String
    "deploy"
  end
end

struct ApplicationCommandTreeTest < ASPEC::TestCase
  @runs = Hash(String, ACON::Input::Interface).new

  def tear_down : Nil
    ENV.delete "COLUMNS"
    ENV.delete "SHELL_VERBOSITY"
  end

  def test_spaced_invocation_runs_the_leaf : Nil
    app = self.create_tree_application

    self.run_tokens(app, "docker", "compose", "up", "web", "--detach").should eq ACON::Command::Status::SUCCESS
    @runs["docker:compose:up"].argument("service").should eq "web"
    @runs["docker:compose:up"].option("detach", Bool).should be_true
  end

  def test_each_level_parses_its_own_options : Nil
    app = self.create_tree_application

    self.run_tokens(app, "docker", "--context=prod", "compose", "-f", "app.yaml", "up", "web").should eq ACON::Command::Status::SUCCESS
    @runs["docker:compose:up"].argument("service").should eq "web"
    @runs["docker:compose:up"].has_option?("file").should be_false
  end

  def test_application_options_bound_at_an_ancestor_level_reach_the_leaf : Nil
    app = self.create_tree_application
    app.definition << ACON::Input::Option.new("stage", value_mode: :required)
    app.definition << ACON::Input::Option.new("color", value_mode: :negatable)
    app.definition << ACON::Input::Option.new("level", value_mode: :optional, default: "1")

    self.run_tokens app, "docker", "--level", "-v", "--stage=blue", "--no-color", "compose", "--ansi", "up"

    input = @runs["docker:compose:up"]
    input.option("verbose", Bool).should be_true
    input.option("stage").should eq "blue"
    input.option("color", Bool).should be_false
    input.option("level").should be_nil
    input.option("ansi", Bool).should be_true
    input.has_parameter?("--stage").should be_true
    input.to_s.should contain "-v --stage=blue --no-color --level --ansi"
  end

  def test_a_repeated_shortcut_is_replayed_as_given : Nil
    app = self.create_tree_application

    self.run_tokens app, "docker", "-vv", "compose", "up"

    input = @runs["docker:compose:up"]
    input.has_parameter?("-vv").should be_true
    input.to_s.should contain "-vv"
  end

  def test_unknown_option_before_a_branch_fails_on_that_level : Nil
    app = self.create_tree_application

    expect_raises ACON::Exception::Runtime, "The '--nope' option does not exist." do
      self.run_tokens app, "docker", "--nope", "compose", "up"
    end
  end

  def test_leaf_keeps_strict_parsing : Nil
    app = self.create_tree_application

    expect_raises ACON::Exception::UnexpectedArgument, "Too many arguments" do
      self.run_tokens app, "docker", "compose", "up", "web", "extra"
    end
  end

  def test_sub_commands_bind_before_argument_slots : Nil
    app = self.create_tree_application

    self.run_tokens(app, "deploy", "rollback").should eq ACON::Command::Status::SUCCESS
    @runs.has_key?("deploy:rollback").should be_true
    @runs.has_key?("deploy").should be_false
  end

  def test_double_dash_binds_arguments_to_the_current_node : Nil
    app = self.create_tree_application

    self.run_tokens(app, "deploy", "--", "rollback").should eq ACON::Command::Status::SUCCESS
    @runs["deploy"].argument("target").should eq "rollback"
    @runs.has_key?("deploy:rollback").should be_false
  end

  def test_node_with_code_still_runs_when_no_sub_command_is_given : Nil
    app = self.create_tree_application

    self.run_tokens(app, "deploy").should eq ACON::Command::Status::SUCCESS
    @runs["deploy"].argument("target").should be_nil
  end

  def test_a_token_naming_no_sub_command_is_the_node_argument : Nil
    app = self.create_tree_application

    self.run_tokens(app, "deploy", "prod").should eq ACON::Command::Status::SUCCESS
    @runs["deploy"].argument("target").should eq "prod"
    @runs.has_key?("deploy:rollback").should be_false
  end

  def test_a_token_naming_no_sub_command_below_the_root_is_that_node_argument : Nil
    app = self.create_tree_application
    app.add self.recording_command("docker:compose").option("file", "f", :required).argument("project")

    self.run_tokens(app, "docker", "compose", "-f", "app.yaml", "api").should eq ACON::Command::Status::SUCCESS
    @runs["docker:compose"].argument("project").should eq "api"
    @runs["docker:compose"].option("file").should eq "app.yaml"
    @runs.has_key?("docker:compose:up").should be_false
  end

  def test_unknown_segment_gets_scoped_alternatives : Nil
    app = self.create_tree_application

    ex = expect_raises ACON::Exception::CommandNotFound, "There is no command 'compos' under 'docker'." do
      self.run_tokens app, "docker", "compos"
    end

    ex.message.not_nil!.should_not contain " -- "
    ex.alternatives.should eq ["docker:compose"]
  end

  def test_implicit_intermediate_levels_route : Nil
    app = self.create_tree_application

    self.run_tokens(app, "tree", "a", "b", "--fast").should eq ACON::Command::Status::SUCCESS
    @runs["tree:a:b"].option("fast", Bool).should be_true
  end

  def test_colon_invocation_is_unchanged : Nil
    app = self.create_tree_application

    self.run_tokens(app, "deploy:rollback").should eq ACON::Command::Status::SUCCESS
    @runs.has_key?("deploy:rollback").should be_true
  end

  def test_bare_group_lists_its_sub_commands : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker"], capture_stderr_separately: true).should eq ACON::Command::Status::FAILURE
    tester.display.should be_empty
    tester.error_output.should contain "docker:compose:up"
  end

  def test_terminal_mid_node_group_lists_its_scope : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker", "compose"], capture_stderr_separately: true).should eq ACON::Command::Status::FAILURE
    tester.display.should be_empty
    tester.error_output.should contain "docker:compose:up"
  end

  def test_implicit_node_lists_its_scope : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["tree", "a"], capture_stderr_separately: true).should eq ACON::Command::Status::FAILURE
    tester.display.should be_empty
    tester.error_output.should contain "tree:a:b"
  end

  def test_group_without_descendants_raises : Nil
    app = self.create_tree_application
    app.add ACON::Commands::Group.new "solo"

    expect_raises ACON::Exception::Logic, "The 'solo' command group does not have any sub-commands." do
      self.run_tokens app, "solo"
    end
  end

  def test_help_on_a_leaf_shows_that_leaf : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker", "compose", "up", "--help"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "docker:compose:up"
    tester.display.should contain "--detach"
    tester.display.should_not contain "--context"
  end

  def test_help_on_a_mid_node_shows_that_node : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker", "compose", "--help"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "--file"
    tester.display.should_not contain "--context"
  end

  def test_help_on_a_tree_root_shows_the_root : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker", "--help"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "--context"
  end

  def test_the_leaf_can_read_ancestor_input_through_the_chain : Nil
    app = self.create_tree_application

    context = nil
    app.register "docker:compose:up" do |_, _, command|
      context = command.application.command_chain.not_nil!.input("docker").try &.option("context")

      ACON::Command::Status::SUCCESS
    end

    self.run_tokens app, "docker", "--context=prod", "compose", "up"

    context.should eq "prod"
  end

  def test_the_chain_is_exposed_while_a_command_runs : Nil
    app = self.create_tree_application

    names = nil
    file = nil
    app.register "docker:compose:up" do |_, _, command|
      chain = command.application.command_chain.not_nil!
      names = chain.commands.map &.name
      file = chain.input("docker:compose").try &.option("file")

      ACON::Command::Status::SUCCESS
    end

    self.run_tokens app, "docker", "compose", "-f", "app.yaml", "up"

    names.should eq ["docker", "docker:compose", "docker:compose:up"]
    file.should eq "app.yaml"
    app.command_chain.should be_nil
  end

  def test_a_flat_run_exposes_a_single_level_chain : Nil
    app = self.create_tree_application

    names = nil
    app.register "deploy:rollback" do |_, _, command|
      names = command.application.command_chain.not_nil!.commands.map &.name

      ACON::Command::Status::SUCCESS
    end

    self.run_tokens app, "deploy:rollback"

    names.should eq ["deploy:rollback"]
  end

  def test_completion_suggests_child_segments : Nil
    self.complete(["docker", ""], 1).should eq ["compose"]
    self.complete(["docker", "comp"], 1).should eq ["compose"]
    self.complete(["tree", "a", ""], 2).should eq ["b"]
  end

  def test_completion_offers_the_node_argument_values_next_to_the_segments : Nil
    self.complete(["deploy", ""], 1).should eq ["rollback", "prod", "staging"]
    self.complete(["docker", "compose", ""], 2).should eq ["up", "api", "web"]
    self.complete(["docker", "compose", "u"], 2).should eq ["up", "api", "web"]
  end

  def test_completion_suggests_the_current_level_options : Nil
    self.complete(["docker", "-"], 1).should contain "--context"
  end

  def test_completion_of_an_unknown_segment_suggests_nothing : Nil
    self.complete(["docker", "foo", ""], 2).should be_empty
  end

  def test_completion_after_a_token_naming_no_sub_command_uses_the_node_definition : Nil
    self.complete(["docker", "compose", "api", ""], 3).should eq ["api", "web"]
  end

  def test_completion_of_a_level_with_an_unknown_option_falls_back_to_the_regular_flow : Nil
    self.complete(["docker", "--nope", ""], 2).should be_empty
  end

  def test_completion_of_a_leaf_uses_the_leaf_definition : Nil
    suggestions = self.complete ["docker", "compose", "up", ""], 3

    suggestions.should contain "web"
    suggestions.should contain "db"
  end

  def test_the_root_listing_collapses_trees : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run ["list"]
    tester.display.should contain "docker"
    tester.display.should contain "deploy"
    tester.display.should_not contain "docker:compose"
    tester.display.should_not contain "deploy:rollback"
  end

  def test_the_namespace_listing_keeps_tree_commands : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run ["list", "docker"]
    tester.display.should contain "docker:compose:up"
  end

  def test_the_help_of_a_node_lists_its_sub_commands : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run ["help", "docker:compose"]
    tester.display.should contain "Available sub-commands:"
    tester.display.should contain "up"
  end

  def test_spaced_invocation_through_application_tester : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["docker", "--context", "prod", "compose", "up", "web"]).should eq ACON::Command::Status::SUCCESS
    @runs["docker:compose:up"].argument("service").should eq "web"
  end

  def test_a_namespace_without_a_registered_root_is_walkable : Nil
    app = self.create_tree_application

    self.run_tokens(app, "ns", "sub", "--fast").should eq ACON::Command::Status::SUCCESS
    @runs["ns:sub"].option("fast", Bool).should be_true
  end

  def test_a_bare_namespace_without_a_registered_root_lists_its_commands : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["ns"], capture_stderr_separately: true).should eq ACON::Command::Status::FAILURE
    tester.display.should be_empty
    tester.error_output.should contain "ns:sub"
  end

  def test_an_unknown_segment_under_a_namespace_gets_scoped_suggestions : Nil
    app = self.create_tree_application

    ex = expect_raises ACON::Exception::CommandNotFound, "There is no command 'subb' under 'ns'" do
      self.run_tokens app, "ns", "subb"
    end

    ex.alternatives.should eq ["ns:sub"]
  end

  def test_completion_works_under_a_namespace_without_a_registered_root : Nil
    self.complete(["ns", "s"], 1).should eq ["sub"]
  end

  def test_completion_of_a_partial_command_name_ending_with_a_colon : Nil
    suggestions = self.complete ["docker:"], 0

    suggestions.should contain "docker:compose"
    suggestions.should contain "docker:compose:up"
  end

  def test_leaf_input_inherits_interactivity : Nil
    app = self.create_tree_application

    input = ACON::Input::ARGV.new ["docker", "compose", "up"]
    input.interactive = false
    app.run input, ACON::Output::Null.new

    @runs["docker:compose:up"].interactive?.should be_false
  end

  def test_an_alias_at_an_intermediate_level_walks_the_canonical_name : Nil
    app = self.create_application
    app.add ACON::Commands::Group.new "docker"
    app.add ACON::Commands::Group.new("docker:compose").aliases("docker:c")
    app.add self.recording_command "docker:compose:up"

    self.run_tokens app, "docker", "c", "up"

    @runs.has_key?("docker:compose:up").should be_true
    self.complete(["docker", "c", "u"], 2, app).should eq ["up"]
  end

  def test_an_alias_under_the_command_own_name_is_not_a_descendant : Nil
    deploy = self.recording_command("deploy").aliases("deploy:prod").argument("target")

    app = self.create_application
    app.add deploy

    self.run_tokens app, "deploy", "prod"
    @runs["deploy"].argument("target").should eq "prod"

    self.run_tokens app, "deploy:prod", "staging"
    @runs["deploy"].argument("target").should eq "staging"

    app = self.create_application
    app.command_loader = ACON::Loader::Factory.new({
      "deploy"      => -> { deploy.as ACON::Command },
      "deploy:prod" => -> { deploy.as ACON::Command },
    })

    self.run_tokens app, "deploy", "prod"
    @runs["deploy"].argument("target").should eq "prod"
  end

  def test_an_alias_resolving_outside_the_tree_keeps_its_sub_commands_reachable : Nil
    app = self.create_application
    app.add self.recording_command("other").aliases("docker:compose").argument("what")
    app.add self.recording_command "docker:compose:up"

    self.run_tokens app, "docker", "compose", "up"
    @runs.has_key?("docker:compose:up").should be_true
    @runs.has_key?("other").should be_false

    self.run_tokens app, "docker", "compose"
    @runs.has_key?("other").should be_true
  end

  def test_a_bare_namespace_holding_only_hidden_commands_reports_the_namespace : Nil
    app = self.create_application
    app.add ACON::Commands::Group.new "ns"
    app.add self.recording_command("ns:secret").hidden

    tester = ACON::Spec::ApplicationTester.new app

    expect_raises ACON::Exception::NamespaceNotFound, "There are no commands defined in the 'ns' namespace." do
      tester.run ["ns"], capture_stderr_separately: true
    end

    tester.display.should be_empty
    tester.error_output.should be_empty
  end

  def test_help_accepts_a_spaced_path : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["help", "docker", "compose"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "docker:compose"
    tester.display.should contain "--file"
    tester.display.should_not contain "--context"
  end

  def test_help_accepts_a_spaced_path_to_an_implicit_node : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["help", "tree", "a"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "tree:a"
  end

  def test_help_keeps_ignoring_tokens_that_name_no_sub_command : Nil
    tester = ACON::Spec::ApplicationTester.new self.create_tree_application

    tester.run(["help", "deploy:rollback", "now"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "deploy:rollback"
  end

  def test_help_wraps_a_lazily_registered_help_command : Nil
    app = self.create_tree_application
    app.add ACON::Commands::Lazy.new("help", [] of String, "", false, -> { ACON::Commands::Help.new.as ACON::Command })

    tester = ACON::Spec::ApplicationTester.new app

    tester.run(["docker", "compose", "--help"]).should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "docker:compose"
  end

  def test_a_nested_run_restores_the_chain : Nil
    app = self.create_tree_application

    names = nil
    app.register "docker:compose:up" do |_, _, command|
      command.application.run ACON::Input::Hash.new(command: "list"), ACON::Output::Null.new
      names = command.application.command_chain.not_nil!.commands.map &.name

      ACON::Command::Status::SUCCESS
    end

    self.run_tokens app, "docker", "compose", "up"

    names.should eq ["docker", "docker:compose", "docker:compose:up"]
  end

  def test_the_chain_is_reset_when_the_command_raises : Nil
    app = self.create_tree_application
    app.register("docker:compose:up") { raise "boom" }

    expect_raises ::Exception, "boom" do
      self.run_tokens app, "docker", "compose", "up"
    end

    app.command_chain.should be_nil
  end

  def test_completion_after_the_double_dash_uses_the_node_arguments : Nil
    self.complete(["deploy", "--", ""], 2).should eq ["prod", "staging"]
    self.complete(["docker", "compose", "--", ""], 3).should eq ["api", "web"]
  end

  def test_completion_keeps_unrelated_lazy_commands_lazy : Nil
    app, instantiated = self.create_lazy_application

    self.complete ["app:one", ""], 1, app
    self.complete ["app:one", "-"], 1, app

    instantiated.should eq ["app:one"]
  end

  def test_the_help_of_an_unknown_path_keeps_lazy_commands_lazy : Nil
    app, instantiated = self.create_lazy_application

    self.run_tokens app, "help", "app:one", "nope"

    instantiated.should eq ["app:one"]
  end

  def test_the_help_of_a_namespace_keeps_unrelated_lazy_commands_lazy : Nil
    app, instantiated = self.create_lazy_application

    self.run_tokens app, "help", "other"

    instantiated.should eq ["other:sub"]
  end

  def test_the_help_of_a_command_keeps_unrelated_lazy_commands_lazy : Nil
    app, instantiated = self.create_lazy_application

    self.run_tokens app, "app:one", "--help"

    instantiated.should eq ["app:one"]
  end

  def test_an_implicit_root_does_not_appear_in_the_chain : Nil
    app = self.create_tree_application

    names = nil
    ns_input = nil
    app.register "ns:sub" do |_, _, command|
      chain = command.application.command_chain.not_nil!
      names = chain.commands.map &.name
      ns_input = chain.input "ns"

      ACON::Command::Status::SUCCESS
    end

    self.run_tokens app, "ns", "sub"

    names.should eq ["ns:sub"]
    ns_input.should be_nil
  end

  def test_a_program_name_command_does_not_walk_the_tree : Nil
    @runs.clear

    app = ProgramNameTreeApplication.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false
    app.use_program_name_as_command = true
    app.add self.recording_command("deploy").argument("target")
    app.add self.recording_command("deploy:rollback")

    self.run_tokens(app, "rollback").should eq ACON::Command::Status::SUCCESS
    @runs["deploy"].argument("target").should eq "rollback"
    @runs.has_key?("deploy:rollback").should be_false
  end

  private def create_application : ACON::Application
    @runs.clear

    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.catch_exceptions = false

    app
  end

  private def create_tree_application : ACON::Application
    app = self.create_application

    app.add ACON::Commands::Group.new("docker").option("context", "c", :required)
    app.add ACON::Commands::Group.new("docker:compose").option("file", "f", :required).argument("project", suggested_values: ["api", "web"])
    app.add self.recording_command("docker:compose:up").argument("service", suggested_values: ["web", "db"]).option("detach", "d")
    app.add self.recording_command("deploy").argument("target", suggested_values: ["prod", "staging"])
    app.add self.recording_command("deploy:rollback")
    app.add ACON::Commands::Group.new("tree")
    app.add self.recording_command("tree:a:b").option("fast")
    app.add self.recording_command("ns:sub").description("A leaf without a registered root").option("fast")

    app
  end

  private def create_lazy_application : {ACON::Application, Array(String)}
    instantiated = [] of String

    factories = Hash(String, Proc(ACON::Command)).new
    {"app:one", "app:two", "other:sub"}.each do |name|
      factories[name] = -> do
        instantiated << name
        ACON::Commands::Generic.new(name) { ACON::Command::Status::SUCCESS }.as ACON::Command
      end
    end

    app = ACON::Application.new "foo"
    app.auto_exit = false
    app.command_loader = ACON::Loader::Factory.new factories

    {app, instantiated}
  end

  private def recording_command(name : String) : ACON::Command
    runs = @runs

    ACON::Commands::Generic.new name do |input|
      runs[name] = input

      ACON::Command::Status::SUCCESS
    end
  end

  private def run_tokens(app : ACON::Application, *tokens : String) : ACON::Command::Status
    app.run ACON::Input::ARGV.new(tokens.to_a), ACON::Output::Null.new
  end

  private def complete(words : Array(String), current : Int32, application : ACON::Application? = nil) : Array(String)
    application ||= self.create_tree_application

    tester = ACON::Spec::CommandTester.new application.get "_complete"
    tester.execute({"--shell" => "bash", "--api-version" => ACON::Commands::Complete::API_VERSION.to_s, "--input" => words, "--current" => current.to_s})

    tester.display(true).split("\n").reject &.empty?
  end
end
