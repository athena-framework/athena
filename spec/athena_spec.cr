require "./spec_helper_methods"
require "../src/athena"

require "file_utils"

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
\tpath : String = "athena.yml"\n
EXPLAIN

DEFAULT_CONFIG_YAML = <<-YAML
---
environments:
  &development development:
    routing:
      cors:
        enabled: false
        strategy: blacklist
        defaults: &defaults
          allow_origin: https://yourdomain.com
          expose_headers: []
          max_age: 0
          allow_credentials: false
          allow_methods: []
          allow_headers: []
        groups: {}
  &test test:
    <<: *development
  &production production:
    <<: *development\n
YAML

Spec.before_each { Crylog::Registry.clear }
Spec.before_each { ENV["ATHENA_ENV"] = "test" }

describe Athena do
  describe "binary" do
    describe "--list -l" do
      it "should list available commands" do
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

        it "should generate the correct yaml" do
          ENV["ATHENA_ENV"] = "development"
          Athena::Config::Environments.new.to_yaml.should eq DEFAULT_CONFIG_YAML
        end
      end
    end
  end

  describe ".config" do
    describe "with the default path" do
      it "should return the standard object" do
        ENV["ATHENA_ENV"] = "test"
        config = Athena.config
        config.routing.cors.enabled.should be_false
        config.routing.cors.groups.empty?.should be_true
        config.routing.cors.defaults.allow_origin.should eq "https://yourdomain.com"
        config.routing.cors.strategy.should eq "blacklist"
      end
    end

    describe "with a provided path" do
      it "should return the standard object" do
        ENV["ATHENA_ENV"] = "test"
        config = Athena.config "spec/routing/athena.yml"
        config.routing.cors.enabled.should be_true
        config.routing.cors.groups.has_key?("class_overload").should be_true
        config.routing.cors.groups.has_key?("action_overload").should be_true
        config.routing.cors.defaults.allow_origin.should eq "DEFAULT_DOMAIN"
        config.routing.cors.strategy.should eq "blacklist"
      end
    end
  end

  describe ".configure_logger" do
    describe "and the logs dir does not exist" do
      it "should create the directory" do
        Athena.logs_dir = "#{Dir.tempdir}/logs"
        FileUtils.rm_rf Athena.logs_dir
        Dir.exists?("#{Dir.tempdir}/logs").should be_false
        Athena.configure_logger
        Dir.exists?("#{Dir.tempdir}/logs").should be_true
      end
    end

    describe "in the development env" do
      it "should add STDOUT and development handlers to the main logger" do
        ENV["ATHENA_ENV"] = "development"
        Athena.configure_logger
        Crylog::Registry.loggers.has_key?("main").should be_true
        main_logger = Athena.logger
        main_logger.channel.should eq "main"
        main_logger.handlers.size.should eq 2
      end
    end

    describe "and we're in the production env" do
      it "should add a single production handler to the main logger" do
        ENV["ATHENA_ENV"] = "production"
        Athena.configure_logger
        Crylog::Registry.loggers.has_key?("main").should be_true
        main_logger = Athena.logger
        main_logger.channel.should eq "main"
        main_logger.handlers.size.should eq 1
      end
    end

    describe "and we're in the test env" do
      it "should add no handlers" do
        Athena.configure_logger
        Crylog::Registry.loggers.has_key?("main").should be_true
        main_logger = Athena.logger
        main_logger.channel.should eq "main"
        main_logger.handlers.should be_empty
      end
    end
  end
end
