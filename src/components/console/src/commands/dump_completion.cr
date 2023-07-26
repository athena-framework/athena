@[Athena::Console::Annotations::AsCommand("completion", description: "Dump the shell completion script")]
# Can be used to generate the [completion script][Athena::Console--console-completion] to enable [argument/option value completion][Athena::Console::Input::Interface--argumentoption-value-completion].
#
# See the related docs for more information.
class Athena::Console::Commands::DumpCompletion < Athena::Console::Command
  private SUPPORTED_SHELLS = {{ Athena::Console::Completion::Output::Interface.subclasses.map(&.name.split("::").last.downcase) }}

  protected def self.guess_shell : String
    File.basename ENV["SHELL"]? || ""
  end

  protected def configure : Nil
    # `Process.executable_path` already resolves symlinks
    full_command = Process.executable_path || ""

    command_name = File.basename full_command

    shell = self.class.guess_shell

    rc_file, completion_file = case shell
                               when "fish" then {"~/.config/fish/config.fish", "/etc/fish/completions/#{command_name}.fish"}
                               when "zsh"  then {"~/.zshrc", "$fpath[1]/_#{command_name}"}
                               else
                                 {"~/.bashrc", "/etc/bash_completion.d/#{command_name}"}
                               end

    supported_shells = SUPPORTED_SHELLS.join ", "

    self
      .argument("shell", description: "The shell type (e.g. 'bash'), the value of the '$SHELL' env var will be used if not provided", suggested_values: SUPPORTED_SHELLS)
      .help(<<-TEXT
The <info>%command.name%</> command dumps the shell completion script required
to use shell autocompletion (currently, #{supported_shells} completion are supported).

<comment>Static installation
-------------------</>

Dump the script to a global completion file and restart your shell:

    <info>%command.full_name% #{shell} | sudo tee #{completion_file}</>

Or dump the script to a local file and source it:

    <info>%command.full_name% #{shell} > completion.sh</>

    <comment># source the file whenever you use the project</>
    <info>source completion.sh</>

    <comment># or add this line at the end of your "#{rc_file}" file:</>
    <info>source /path/to/completion.sh</>

<comment>Dynamic installation
--------------------</>

Add this to the end of your shell configuration file (e.g. <info>"#{rc_file}"</>):

    <info>eval "$(#{full_command} completion #{shell})"</>
TEXT
      )
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    command_name = File.basename Process.executable_path || ""

    # Prevent generating the file for *.tmp files.
    # It'll not only run slow, but probably not even valid bash syntax.
    if command_name.ends_with? ".tmp"
      raise ACON::Exceptions::RuntimeError.new "The shell completion file may only be generated non-temporary binaries.\n\nTry to `crystal build` your application first and try again."
    end

    shell = input.argument("shell") || self.class.guess_shell

    completion_script = case shell
                        when "bash" then ACON::Completion::Output::Bash::Script.new command_name, ACON::Commands::Complete::API_VERSION
                        when "fish" then ACON::Completion::Output::Fish::Script.new command_name, ACON::Commands::Complete::API_VERSION
                        when "zsh"  then ACON::Completion::Output::Zsh::Script.new command_name, ACON::Commands::Complete::API_VERSION
                        else
                          if output.is_a? ACON::Output::ConsoleOutputInterface
                            output = output.error_output
                          end

                          if shell
                            output.puts %(<error>Detected shell '#{shell}', which is not supported by Athena shell completion (supported shells: '#{SUPPORTED_SHELLS.join("', '")}'.))
                          else
                            output.puts %(<error>Shell not detected, Athena shell completion only supports '#{SUPPORTED_SHELLS.join("', '")}'.)
                          end

                          return ACON::Command::Status::INVALID
                        end

    output.print completion_script

    ACON::Command::Status::SUCCESS
  end
end
