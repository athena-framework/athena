#compdef <%= @command_name %>

#
# zsh completions for <%= @command_name %>
#
# References:
#   - https://github.com/symfony/symfony/blob/503a7b3cb62fb6de70176b07bd1c4242e3addc5b/src/Symfony/Component/Console/Resources/completion.zsh

_athena_<%= @command_name %>() {
    local lastParam flagPrefix requestComp out comp
    local -a completions

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
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    # Prepare the command to obtain completions
    # Crystal doesn\'t get the script as the first arg, so skip it when iterating over `words` and decrement CURRENT by 2 instead of 1 to compensate
    requestComp="${words[0]} ${words[1]} _complete --no-interaction -szsh -a<%= @version %> -c$((CURRENT-2))" i=""
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
            i="${i}-i${w} "
        fi
    done

    # Ensure at least 1 input
    if [ "${i}" = "" ]; then
        requestComp="${requestComp} -i\" \""
    else
        requestComp="${requestComp} ${i}"
    fi

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)

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
    eval _describe "completions" completions $flagPrefix
    return $?
}

compdef _athena_<%= @command_name %> <%= @command_name %> ./<%= @command_name %>
