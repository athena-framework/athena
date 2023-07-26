# Adapted from https://github.com/symfony/symfony/blob/503a7b3cb62fb6de70176b07bd1c4242e3addc5b/src/Symfony/Component/Console/Resources/completion.fish

function _athena_{{ COMMAND_NAME }}
    set athena_cmd (commandline -o)
    set c (count (commandline -oc))

    set completecmd "$athena_cmd[1]" "_complete" "--no-interaction" "-sfish" "-a{{ VERSION }}"

    for i in $athena_cmd
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

complete -c '{{ COMMAND_NAME }}' -a '(_athena_{{ COMMAND_NAME }})' -f
