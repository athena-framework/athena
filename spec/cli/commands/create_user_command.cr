require "../cli_spec_helper"

struct CreateUserCommand < Athena::Cli::Command
  def self.execute(id : Int32) : Nil
    it "should pass params correctly" do
      id.should be_a(Int32)
      id.should eq 123
      SpecHelper.logger.info "CreateUserCommand Success"
    end
  end
end
