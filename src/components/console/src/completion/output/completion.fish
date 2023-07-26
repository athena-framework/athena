# Adapted from https://github.com/symfony/symfony/blob/503a7b3cb62fb6de70176b07bd1c4242e3addc5b/src/Symfony/Component/Console/Resources/completion.fish
# Crystal doesn\'t get the script as the first arg, so remove it and decrement c by 1 to compensate

function _athena_<%= @command_name %>
    set athena_cmd (commandline -o)
    set c (math (count (commandline -oc)) - 1)

    set completecmd "$athena_cmd[1]" "_complete" "--no-interaction" "-sfish" "-a<%= @version %>"

    for i in $athena_cmd[2..]
        if [ $i != "" ]
            set completecmd $completecmd "-i$i"
        end
    end

    set completecmd $completecmd "-c$c"

    set sfcomplete ($completecmd)

    for i in $sfcomplete
        echo $i
    end
end

complete -c '<%= @command_name %>' -a '(_athena_<%= @command_name %>)' -f
