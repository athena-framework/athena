#compdef <%= @command_name %>

#
# zsh completions for <%= @command_name %>
#
# References:
#   - https://github.com/symfony/symfony/blob/ea4569ce9fc21d6bae180274e1b4d3ca19dd5002/src/Symfony/Component/Console/Resources/completion.zsh

_athena_<%= @command_name %>() {
    local lastParam out comp completion_cmd
    local -a completions flagPrefix requestComp inputs

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}") lastParam=${words[-1]}

    # For zsh, when completing a flag with an = (e.g., <%= @command_name %> -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix=(-P "${BASH_REMATCH}")
    fi

    # Prepare the command to obtain completions. An alias is resolved here, as the request is not read again by the shell.
    completion_cmd="${words[1]}"
    if [[ -n "${aliases[$completion_cmd]}" ]]; then
        requestComp=(${(z)aliases[$completion_cmd]})
    else
        requestComp=(${~completion_cmd})
    fi

    # Crystal doesn\'t get the script as the first arg, so skip it when iterating over `words` and decrement CURRENT by 2 instead of 1 to compensate
    requestComp+=(_complete --no-interaction -szsh -a<%= @version %> "-c$((CURRENT-2))")

    for w in ${words[@]:1}; do
        w=$(printf -- '%b' "$w")
        # remove quotes from typed values
        quote="${w:0:1}"
        if [ "$quote" = \' ]; then
            w="${w%\'}"
            w="${w#\'}"
        elif [ "$quote" = \" ]; then
            w="${w%\"}"
            w="${w#\"}"
        fi
        # empty values are ignored
        if [ ! -z "$w" ]; then
            inputs+=("-i$w")
        fi
    done

    # Ensure at least 1 input
    if (( ! $#inputs )); then
        inputs=(-i' ')
    fi

    # The request is run without being read again by the shell, so that a "$(...)" or a backtick typed on the command line is not executed
    out=$(SHELL_VERBOSITY=0 "${requestComp[@]}" "${inputs[@]}" 2>/dev/null)

    while IFS='\n' read -r comp; do
        if [ -n "$comp" ]; then
            # If requested, completions are returned with a description.
            # The description is preceded by a TAB character.
            # For zsh\'s _describe, we need to use a : instead of a TAB.
            # We first need to escape any : as part of the completion itself.
            comp=${comp//:/\\:}
            local tab=$(printf '\t')
            comp=${comp//$tab/:}
            completions+=${comp}
        fi
    done < <(printf "%s\n" "${out[@]}")

    # Let inbuilt _describe handle completions
    _describe "completions" completions "${flagPrefix[@]}"
    return $?
}

compdef _athena_<%= @command_name %> <%= @command_name %> ./<%= @command_name %>
