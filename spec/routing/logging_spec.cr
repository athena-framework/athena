require "./routing_spec_helper"

TIME_REGEX = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{9}Z/

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

    do_with_config do |client|
      describe "when a 500 occurs" do
        it "should log the proper messages" do
          handler = Crylog::Handlers::TestHandler.new

          Crylog.configure do |registry|
            registry.register "main" do |logger|
              logger.handlers = [handler] of Crylog::Handlers::LogHandler
            end
          end

          client.get("/exception/default")
          handler.messages.size.should eq 2

          handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'get_default_exception' {"path":"\/exception\/default","method":"GET","remote_address":".*","version":"HTTP\/1\.1","length":null}/
          handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.CRITICAL: Unhandled exception: Nil assertion failed in Test2 at spec\/routing\/controllers\/exception_controller.cr:\d+:\d+ {\"cause\":null,\"cause_class\":\"Nil\"}/
        end
      end

      describe CrSerializer::Exceptions::ValidationException do
        it "should log the proper messages" do
          handler = Crylog::Handlers::TestHandler.new

          Crylog.configure do |registry|
            registry.register "main" do |logger|
              logger.handlers = [handler] of Crylog::Handlers::LogHandler
            end
          end

          client.post("/users", body: %({"age":-12}), headers: HTTP::Headers{"content-type" => "application/json"})
          handler.messages.size.should eq 2

          handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'new_user' {"path":"\/users","method":"POST","remote_address":".*","version":"HTTP\/1\.1","length":11}/
          handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.NOTICE: Validation tests failed: `'age' should be greater than 0`\./
        end
      end
      client.get("/int32/1.00")

      describe Athena::Routing::Exceptions::AthenaException do
        it "should log the proper messages" do
          handler = Crylog::Handlers::TestHandler.new

          Crylog.configure do |registry|
            registry.register "main" do |logger|
              logger.handlers = [handler] of Crylog::Handlers::LogHandler
            end
          end

          client.get("/users/34")
          handler.messages.size.should eq 2

          handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'get_user' {"path":"\/users\/34","method":"GET","remote_address":".*","version":"HTTP\/1\.1","length":null}/
          handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.NOTICE: Unhandled AthenaException: {"code":404,"message":"An item with the provided ID could not be found."}/
        end
      end

      describe ArgumentError do
        it "should log the proper messages" do
          handler = Crylog::Handlers::TestHandler.new

          Crylog.configure do |registry|
            registry.register "main" do |logger|
              logger.handlers = [handler] of Crylog::Handlers::LogHandler
            end
          end

          client.get("/int32/1.00")
          handler.messages.size.should eq 2

          handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'int32' {"path":"\/int32\/1.00","method":"GET","remote_address":".*","version":"HTTP\/1\.1","length":null}/
          handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.NOTICE: Unhandled ArgumentError: Invalid Int32: 1.00/
        end
      end

      describe JSON::ParseException do
        describe "not nilable" do
          it "should log the proper messages" do
            handler = Crylog::Handlers::TestHandler.new

            Crylog.configure do |registry|
              registry.register "main" do |logger|
                logger.handlers = [handler] of Crylog::Handlers::LogHandler
              end
            end

            client.post("/users", body: %({"age": true}), headers: HTTP::Headers{"content-type" => "application/json"})
            handler.messages.size.should eq 2

            handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'new_user' {"path":"\/users","method":"POST","remote_address":".*","version":"HTTP\/1\.1","length":13}/
            handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.NOTICE: Expected 'age' to be int but got bool/
          end
        end

        describe "nilable" do
          it "should log the proper messages" do
            handler = Crylog::Handlers::TestHandler.new

            Crylog.configure do |registry|
              registry.register "main" do |logger|
                logger.handlers = [handler] of Crylog::Handlers::LogHandler
              end
            end

            client.post("/users", body: %({"id": "123","age": 100}), headers: HTTP::Headers{"content-type" => "application/json"})
            handler.messages.size.should eq 2

            handler.messages[0].formatted.should match /\[#{TIME_REGEX}\] main.INFO: Matched route 'new_user' {"path":"\/users","method":"POST","remote_address":".*","version":"HTTP\/1\.1","length":24}/
            handler.messages[1].formatted.should match /\[#{TIME_REGEX}\] main.NOTICE: Couldn't parse Int64 | Nil from '"123"'/
          end
        end
      end
    end
  end
end
