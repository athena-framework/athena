require "./routing_spec_helper"

module Athena
  describe Athena do
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
          main_logger.handlers.first.should_not eq Crylog::Handlers::IOHandler.new(STDOUT)
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
end
