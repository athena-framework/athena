require "./spec_helper"

abstract class ACON::Command
  def merge_application_definition(merge_args : Bool = true) : Nil
    previous_def
  end
end

describe ACON::Command do
  describe ".new" do
    describe "when configured via annotation" do
      it "sets name and description" do
        command = AnnotationConfiguredCommand.new
        command.name.should eq "annotation:configured"
        command.description.should eq "Command configured via annotation"
        command.hidden?.should be_false
        command.aliases.should eq ["ac"]
      end

      it "sets the command as hidden if its name is an empty string" do
        command = AnnotationConfiguredHiddenCommand.new
        command.name.should eq "annotation:configured"
        command.hidden?.should be_true
        command.aliases.should be_empty
      end

      it "sets the command as hidden if that field is true" do
        command = AnnotationConfiguredHiddenFieldCommand.new
        command.name.should eq "annotation:configured"
        command.hidden?.should be_true
        command.aliases.should be_empty
      end

      it "sets aliases" do
        command = AnnotationConfiguredAliasesCommand.new
        command.name.should eq "annotation:configured"
        command.hidden?.should be_false
        command.aliases.should eq ["ac"]
      end
    end

    it "prioritizes constructor args" do
      command = AnnotationConfiguredCommand.new "cv"
      command.name.should eq "cv"
      command.description.should eq "Command configured via annotation"
    end

    it "raises on invalid name" do
      expect_raises ACON::Exceptions::InvalidArgument, "Command name '' is invalid." do
        AnnotationConfiguredCommand.new ""
      end

      expect_raises ACON::Exceptions::InvalidArgument, "Command name '  ' is invalid." do
        AnnotationConfiguredCommand.new "  "
      end

      expect_raises ACON::Exceptions::InvalidArgument, "Command name 'foo:' is invalid." do
        AnnotationConfiguredCommand.new "foo:"
      end
    end
  end

  describe "#application=" do
    it "sets the helper_set and application" do
      app = ACON::Application.new "foo"
      command = TestCommand.new
      command.application = app

      command.application.should be app
      command.helper_set.should be app.helper_set
    end

    it "clears out the command's helper_set when clearing out the application" do
      command = TestCommand.new
      command.application = nil
      command.helper_set.should be_nil
    end
  end

  describe "get/set definition" do
    command = TestCommand.new
    command.definition definition = ACON::Input::Definition.new
    command.definition.should be definition

    command.definition ACON::Input::Argument.new("foo"), ACON::Input::Option.new("bar")
    command.definition.has_argument?("foo").should be_true
    command.definition.has_option?("bar").should be_true
  end

  describe "#argument" do
    it "basic form" do
      command = TestCommand.new
      command.argument "foo"
      command.definition.has_argument?("foo").should be_true
    end
    describe "suggested values" do
      it "array" do
        command = TestCommand.new
        command.argument "foo", suggested_values: {"a", "b", "c"}
        command.definition.has_argument?("foo").should be_true
        command.definition.argument("foo").has_completion?.should be_true
      end

      it "block" do
        command = TestCommand.new
        command.argument "foo" do
          ["a", "b"]
        end
        command.definition.has_argument?("foo").should be_true
        command.definition.argument("foo").has_completion?.should be_true
      end
    end
  end

  describe "#option" do
    it "basic form" do
      command = TestCommand.new
      command.option "bar"
      command.definition.has_option?("bar").should be_true
    end

    describe "suggested values" do
      it "array" do
        command = TestCommand.new
        command.option "foo", value_mode: :required, suggested_values: {"a", "b", "c"}
        command.definition.has_option?("foo").should be_true
        command.definition.option("foo").has_completion?.should be_true
      end

      it "block" do
        command = TestCommand.new
        command.option "foo", value_mode: :required do
          ["a", "b"]
        end
        command.definition.has_option?("foo").should be_true
        command.definition.option("foo").has_completion?.should be_true
      end
    end
  end

  describe "#processed_help" do
    it "replaces placeholders correctly" do
      command = TestCommand.new
      command.help = "The %command.name% command does... Example: %command.full_name%."
      command.processed_help.should start_with "The namespace:name command does"
      command.processed_help.should_not contain "%command.full_name%"
    end

    it "falls back on the description" do
      command = TestCommand.new
      command.help = ""
      command.processed_help.should eq "description"
    end
  end

  describe "#synopsis" do
    it "long" do
      TestCommand.new.option("foo").argument("bar").argument("info").synopsis.should eq "namespace:name [--foo] [--] [<bar> [<info>]]"
    end

    it "short" do
      TestCommand.new.option("foo").argument("bar").synopsis(true).should eq "namespace:name [options] [--] [<bar>]"
    end
  end

  describe "#usages" do
    it "that starts with the command's name" do
      TestCommand.new.usage("namespace:name foo").usages.should contain "namespace:name foo"
    end

    it "that doesn't include the command's name" do
      TestCommand.new.usage("bar").usages.should contain "namespace:name bar"
    end
  end

  # TODO: Does `#merge_application_definition` need explicit tests?

  describe "#run" do
    it "interactive" do
      tester = ACON::Spec::CommandTester.new TestCommand.new
      tester.execute interactive: true
      tester.display.should eq "interact called#{EOL}execute called#{EOL}"
    end

    it "non-interactive" do
      tester = ACON::Spec::CommandTester.new TestCommand.new
      tester.execute interactive: false
      tester.display.should eq "execute called#{EOL}"
    end

    it "invalid option" do
      tester = ACON::Spec::CommandTester.new TestCommand.new

      expect_raises ACON::Exceptions::InvalidOption, "The '--bar' option does not exist." do
        tester.execute "--bar": true
      end
    end
  end
end
