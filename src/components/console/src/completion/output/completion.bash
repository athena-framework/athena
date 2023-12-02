# Adapted from https://github.com/symfony/symfony/blob/503a7b3cb62fb6de70176b07bd1c4242e3addc5b/src/Symfony/Component/Console/Resources/completion.bash

_athena_<%= @command_name %>() {
    # Use the default completion for shell redirect operators.
    for w in '>' '>>' '&>' '<'; do
        if [[ $w = "${COMP_WORDS[COMP_CWORD-1]}" ]]; then
            compopt -o filenames
            COMPREPLY=($(compgen -f -- "${COMP_WORDS[COMP_CWORD]}"))
            return 0
        fi
    done

    # Use newline as only separator to allow space in completion values
    IFS=$'\n'
    local completion_cmd="${COMP_WORDS[0]}"

    # for an alias, get the real script behind it
    completion_cmd_type=$(type -t $completion_cmd)
    if [[ $completion_cmd_type == "alias" ]]; then
        completion_cmd=$(alias $completion_cmd | sed -E "s/alias $completion_cmd='(.*)'/\1/")
    elif [[ $completion_cmd_type == "file" ]]; then
        completion_cmd=$(type -p $completion_cmd)
    fi

    if [[ $completion_cmd_type != "function" && ! -x $completion_cmd ]]; then
        return 1
    fi

    local cur prev words cword
    _get_comp_words_by_ref -n := cur prev words cword

    # Crystal doesn\'t get the script as the first arg, so remove it and decrement cword by 1 to compensate
    cword=$(expr $cword - 1)
    words=("${words[@]:1}")

    local completecmd=("$completion_cmd" "_complete" "--no-interaction" "-sbash" "-c$cword" "-a<%= @version %>")
    for w in ${words[@]}; do
        w=$(printf -- '%b' "$w")
        # remove quotes from typed values
        quote="${w:0:1}"
        if [ "$quote" == \' ]; then
            w="${w%\'}"
            w="${w#\'}"
        elif [ "$quote" == \" ]; then
            w="${w%\"}"
            w="${w#\"}"
        fi
        # empty values are ignored
        if [ ! -z "$w" ]; then
            completecmd+=("-i$w")
        fi
    done

    local sfcomplete
    if sfcomplete=$(${completecmd[@]} 2>&1); then
        local quote suggestions
        quote=${cur:0:1}

        # Use single quotes by default if suggestions contains backslash (FQCN)
        if [ "$quote" == '' ] && [[ "$sfcomplete" =~ \\ ]]; then
            quote=\'
        fi

        if [ "$quote" == \' ]; then
            # single quotes: no additional escaping (does not accept ' in values)
            suggestions=$(for s in $sfcomplete; do printf $'%q%q%q\n' "$quote" "$s" "$quote"; done)
        elif [ "$quote" == \" ]; then
            # double quotes: double escaping for \ $ ` "
            suggestions=$(for s in $sfcomplete; do
                s=${s//\\/\\\\}
                s=${s//\$/\\\$}
                s=${s//\`/\\\`}
                s=${s//\"/\\\"}
                printf $'%q%q%q\n' "$quote" "$s" "$quote";
            done)
        else
            # no quotes: double escaping
            suggestions=$(for s in $sfcomplete; do printf $'%q\n' $(printf '%q' "$s"); done)
        fi
        COMPREPLY=($(IFS=$'\n' compgen -W "$suggestions" -- $(printf -- "%q" "$cur")))
        __ltrim_colon_completions "$cur"
    else
        if [[ "$sfcomplete" != *"Command \"_complete\" is not defined."* ]]; then
            >&2 echo
            >&2 echo $sfcomplete
        fi

        return 1
    fi
}

complete -F _athena_<%= @command_name %> <%= @command_name %> ./<%= @command_name %> ./bin/<%= @command_name %>
