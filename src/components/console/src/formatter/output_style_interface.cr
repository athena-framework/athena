require "colorize"

# Output styles represent reusable formatting information that can be used when formatting output messages.
# `Athena::Console` comes bundled with a few common styles including:
#
# * error
# * info
# * comment
# * question
#
# Whenever you output text via an `ACON::Output::Interface`, you can surround the text with tags to color its output. For example:
#
# ```
# # Green text
# output.puts "<info>foo</info>"
#
# # Yellow text
# output.puts "<comment>foo</comment>"
#
# # Black text on a cyan background
# output.puts "<question>foo</question>"
#
# # White text on a red background
# output.puts "<error>foo</error>"
# ```
#
# ## Custom Styles
#
# Custom styles can also be defined/used:
#
# ```
# my_style = ACON::Formatter::OutputStyle.new :red, "#f87b05", Colorize::Mode.flags Bold, Underline
# output.formatter.set_style "fire", my_style
#
# output.puts "<fire>foo</>"
# ```
#
# ### Global Custom Styles
#
# You can also make your style global by extending `ACON::Application` and adding it within the `#configure_io` method:
#
# ```
# class MyCustomApplication < ACON::Application
#   protected def configure_io(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
#     super
#
#     my_style = ACON::Formatter::OutputStyle.new :red, "#f87b05", Colorize::Mode.flags Bold, Underline
#     output.formatter.set_style "fire", my_style
#   end
# end
# ```
#
# ## Inline Styles
#
# Styles can also be defined inline when printing a message:
#
# ```
# # Using named colors
# output.puts "<fg=green>foo</>"
#
# # Using hexadecimal colors
# output.puts "<fg=#c0392b>foo</>"
#
# # Black text on a cyan background
# output.puts "<fg=black;bg=cyan>foo</>"
#
# # Bold text on a yellow background
# output.puts "<bg=yellow;options=bold>foo</>"
#
# # Bold text with underline.
# output.puts "<options=bold,underline>foo</>"
# ```
#
# ## Clickable Links
#
# Commands can use the special `href` tag to display links within the console.
#
# ```
# output.puts "<href=https://athenaframework.org>Athena</>"
# ```
#
# If your terminal [supports](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda) it, you would be able to click
# the text and have it open in your default browser. Otherwise, you will see it as regular text.
module Athena::Console::Formatter::OutputStyleInterface
  # Sets the foreground color of `self`.
  abstract def foreground=(foreground : Colorize::Color)

  # Sets the background color of `self`.
  abstract def background=(background : Colorize::Color)

  # Adds a text mode to `self`.
  abstract def add_option(option : Colorize::Mode) : Nil

  # Removes a text mode to `self`.
  abstract def remove_option(option : Colorize::Mode) : Nil

  # Applies `self` to the provided *text*.
  abstract def apply(text : String) : String
end
