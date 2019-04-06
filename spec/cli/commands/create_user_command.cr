require "../cli_spec_helper"

struct CreateUserCommand < Athena::Cli::Command
  self.name = "user"
  self.description = "Creates a user with the given id"

  def self.execute(id : Int32) : Int32
    id.should be_a(Int32)
    id.should eq 123
    id - 23
  end
end
