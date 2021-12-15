require "./spec_helper"

describe ASPEC::Methods do
  describe "#assert_error" do
    it do
      assert_error "abstract_class.cr", "can't instantiate abstract class Foo"
    end
  end

  describe "#run_executable" do
    it "without input" do
      run_executable "ls", ["./.github"] do |output, error, status|
        output.should eq %(workflows\n)
        error.should be_empty
        status.success?.should be_true
      end
    end

    it "with input" do
      input = IO::Memory.new "foo\nbar"

      run_executable "cat", input, ["-e"] do |output, error, status|
        output.should eq "foo$\nbar"
        error.should be_empty
        status.success?.should be_true
      end
    end

    it "with error output" do
      run_executable "cat", args: ["missing.txt"] do |output, error, status|
        output.should be_empty
        error.should contain "No such file or directory"
        status.success?.should be_false
      end
    end
  end
end
