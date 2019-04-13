require "./cli_spec_helper"

describe Athena::Cli do
  describe "with a command that does not have an .execute method" do
    it "should not compile" do
      assert_error "cli/compiler/no_execute.cr", "NoExecuteCommand must implement a `self.execute` method."
    end
  end
end
