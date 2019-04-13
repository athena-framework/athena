require "./spec_helper_methods"
require "../src/athena"

COMMANDS = <<-COMMANDS
Registered Commands:
\tathena
\t\tathena:generate:config_file - Generates the default config file for Athena\n
COMMANDS

EXPLAIN = <<-EXPLAIN
Command
\tathena:generate:config_file - Generates the default config file for Athena
Usage
\t./YOUR_BINARY -c athena:generate:config_file [arguments]
Arguments
\toverride : Bool = false
\tpath : String = "./athena.yml"\n
EXPLAIN

describe Athena do
  describe "binary" do
    describe "--list -l" do
      it "should list avaliable commands" do
        run_binary(args: ["-l"]) do |output|
          output.should eq COMMANDS
        end
      end
    end

    describe "--explain -e" do
      it "should print the help" do
        run_binary(args: ["-e", "athena:generate:config_file"]) do |output|
          output.should eq EXPLAIN
        end
      end
    end

    describe Athena::Commands do
      describe "athena:generate:config_file" do
        describe "when the config file already exists" do
          it "should not recreate the file" do
            created = File.info "athena.yml"
            run_binary(args: ["-c", "athena:generate:config_file"]) do |_output|
              modified = File.info "athena.yml"
              created.modification_time.should eq modified.modification_time
            end
          end
        end

        describe "when using the override flag" do
          it "should recreate the file" do
            original = File.info "athena.yml"
            run_binary(args: ["-c", "athena:generate:config_file", "--override=true"]) do |_output|
              new = File.info "athena.yml"
              (original.modification_time < new.modification_time).should be_true
            end
          end
        end

        describe "when using the path flag" do
          it "should create the file at the given location" do
            File.exists?("#{Dir.tempdir}/athena.yml").should be_false
            run_binary(args: ["-c", "athena:generate:config_file", "--path=#{Dir.tempdir}/athena.yml"]) do |_output|
              File.exists?("#{Dir.tempdir}/athena.yml").should be_true
              File.delete("#{Dir.tempdir}/athena.yml")
            end
          end
        end
      end
    end
  end
end
