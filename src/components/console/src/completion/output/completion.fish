# Adapted from https://github.com/symfony/symfony/blob/ea4569ce9fc21d6bae180274e1b4d3ca19dd5002/src/Symfony/Component/Console/Resources/completion.fish
# Crystal doesn\'t get the script as the first arg, so remove it and decrement c by 1 to compensate

function _athena_<%= @command_name %>
    set athena_cmd (commandline -o)
    set c (math (count (commandline -oc)) - 1)

    # fish completes the whole "--option=value" token, so the option is prepended to the suggestions to let fish filter them
    set flag_prefix ""
    if [ (count $athena_cmd) -gt (count (commandline -oc)) ]; and string match -qr '^-[^=]*=' -- $athena_cmd[-1]
        set flag_prefix (string replace -r '=.*$' '=' -- $athena_cmd[-1])
    end

    set completecmd "$athena_cmd[1]" "_complete" "--no-interaction" "-sfish" "-a<%= @version %>"

    for i in $athena_cmd[2..]
        if [ $i != "" ]
            set completecmd $completecmd "-i$i"
        end
    end

    set completecmd $completecmd "-c$c"

    set sfcomplete (env SHELL_VERBOSITY=0 $completecmd)

    for i in $sfcomplete
        echo "$flag_prefix$i"
    end
end

complete -c '<%= @command_name %>' -a '(_athena_<%= @command_name %>)' -f
