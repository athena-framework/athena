require "./cli_spec_helper"

module Athena
  describe Athena do
    describe ".configure_logger" do
      describe "and we're in any env" do
        it "should contain just a single logger" do
          Athena.configure_logger
          Crylog::Registry.loggers.has_key?("main").should be_true
          main_logger = Athena.logger
          main_logger.channel.should eq "main"
          main_logger.handlers.size.should eq 1
          main_logger.handlers.first.should eq Crylog::Handlers::IOHandler.new(STDOUT)
        end
      end
    end
  end
end
