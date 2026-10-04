require "./spec_helper"

private class ChainTestUpCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Command::Status::SUCCESS
  end
end

struct CommandChainTest < ASPEC::TestCase
  def test_chain_access : Nil
    docker = ACON::Commands::Group.new "docker"
    up = ChainTestUpCommand.new "docker:compose:up"
    docker_input = ACON::Input::Hash.new
    up_input = ACON::Input::Hash.new

    chain = ACON::CommandChain.new [{docker, docker_input}, {up, up_input}] of {ACON::Command, ACON::Input::Interface}

    chain.commands.should eq [docker, up]
    chain.inputs.should eq [docker_input, up_input]

    chain.input("docker").should be docker_input
    chain.input("docker:compose:up").should be up_input
    chain.input(ChainTestUpCommand).should be up_input
    chain.input("nope").should be_nil
    chain.input(ACON::Commands::Help).should be_nil

    chain.command("docker").should be docker
    chain.command(ChainTestUpCommand).should be up
    chain.command("nope").should be_nil
    chain.command(ACON::Commands::Help).should be_nil
  end

  def test_class_lookup_prefers_the_deepest_level : Nil
    docker = ChainTestUpCommand.new "docker"
    up = ChainTestUpCommand.new "docker:compose:up"

    chain = ACON::CommandChain.new [{docker, ACON::Input::Hash.new}, {up, ACON::Input::Hash.new}] of {ACON::Command, ACON::Input::Interface}

    chain.command(ChainTestUpCommand).should be up
    chain.command(ACON::Command).should be up
    chain.command("docker").should be docker
  end
end
