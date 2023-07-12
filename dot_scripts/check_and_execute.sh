check_and_execute() {
    local command="$1"
    shift
    if command -v "$command" >/dev/null 2>&1; then
        "$command" "$@"
        return $?
    else
        return 127
    fi
}
