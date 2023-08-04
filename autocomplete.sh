_script()
{
    COMPREPLY=($(compgen -W "generate_files build flash connect inte prod fpm restore forcebootload change_wifi log_netcom" "${COMP_WORDS[$COMP_CWORD]}"))
}
complete -F _script emb_gw.sh