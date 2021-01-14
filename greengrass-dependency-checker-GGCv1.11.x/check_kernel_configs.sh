readonly NAMESPACE_CONFIGS="IPC_NS UTS_NS USER_NS PID_NS"
readonly CGROUP_CONFIGS="CGROUP_DEVICE CGROUPS MEMCG"
readonly OTHER_REQUIRED_CONFIGS="POSIX_MQUEUE OVERLAY_FS HAVE_ARCH_SECCOMP_FILTER SECCOMP_FILTER KEYS SECCOMP SHMEM INOTIFY_USER"

## Global flag to indicate if the kernel config file is in .gz format.
FILE_IS_GZ=0

MISSING_CONFIGS_LIST=""

################################################################################
## Assume that the 'zgrep' command is not available on the host and define a
## custom zgrep.
################################################################################
zgrep() {
    local match_pattern="$1"
    local kernel_config_file="$2"

    $ZCAT "$kernel_config_file" | $GREP "$match_pattern" 2>/dev/null 1>&2
}

cat_and_grep() {
    local kernel_config_file="$1"
    local match_pattern="$2"

    $CAT "$kernel_config_file" | $GREP "$match_pattern" 2>/dev/null 1>&2
}

################################################################################
## Looks for the pattern '<kernel-config>=y' or '<kernel-config>=m' in the
## kernel config file, i.e, determines if a kernel config is enabled.
################################################################################
search() {
    local match_pattern="$1"
    local kernel_config_file="$2"

    if [ $FILE_IS_GZ -eq 1 ]
    then
        zgrep "$match_pattern" "$kernel_config_file"
    else
        cat_and_grep "$kernel_config_file" "$match_pattern"
    fi
}

################################################################################
## Checks if a config is enabled in the kernel.
################################################################################
is_set_in_kernel() {
    local kernel_config="$1"
    local kernel_config_file="$2"

    search "$kernel_config=y" "$kernel_config_file"
}

################################################################################
## Checks if a config is enabled as a module.
################################################################################
is_set_as_module() {
    local kernel_config="$1"
    local kernel_config_file="$2"

    search "$kernel_config=m" "$kernel_config_file"
}

################################################################################
## Checks if a kernel config is enabled - built in the kernel or enabled as a
## module.
################################################################################
check_if_enabled() {
    local kernel_config="$1"
    local kernel_config_file="$2"

    {
        is_set_in_kernel "$kernel_config" "$kernel_config_file" && wrap_good "$kernel_config" "Enabled"
    } || {
        is_set_as_module "$kernel_config" "$kernel_config_file" && wrap_good "$kernel_config" "Enabled"
    } || {
        wrap_bad "$kernel_config" 'Not enabled'
        MISSING_CONFIGS_LIST="$MISSING_CONFIGS_LIST$kernel_config\n"
    }
}

################################################################################
## Returns the path of the kernel config file in the global variable
## 'KERNEL_CONFIG_FILE'.
################################################################################
get_kernel_config_file() {
    local message
    local user_provided_config_file="$1"
    local kernel_version="$($UNAME -r)"

    ## Trim the '+' charater, if any, from the tail end of the kernel version string.
    kernel_version="${kernel_version%%+}"

    ## Check if the user-provided kernel config file, if any, is valid.
    if [ "$user_provided_config_file" = "" ]
    then
        message="Kernel config file not specified on the command line."
        message="$message Trying '/boot/config-$kernel_version'"
        debug "$message"
    elif [ ! -f "$user_provided_config_file" ]
    then
        message="Kernel config file '$user_provided_config_file' was not found."
        message="$message\nFalling back to '/boot/config-$kernel_version' or"
        message="$message /proc/config.gz"
        warn "$message"
        add_to_warnings "$message"
    else
        KERNEL_CONFIG_FILE="$user_provided_config_file"
        return
    fi

    ## Fallback to '/boot/config-<kernel-version>', if it exists.
    if [ -f "/boot/config-$kernel_version" ]
    then
        KERNEL_CONFIG_FILE="/boot/config-$kernel_version"
        return
    fi

    ## Fallback to '/proc/config.gz', if it exists.
    debug "File /boot/config-$kernel_version was not found. Trying /proc/config.gz"
    if [ -f "/proc/config.gz" ]
    then
        KERNEL_CONFIG_FILE="/proc/config.gz"
        return
    fi

    KERNEL_CONFIG_FILE=""
}

################################################################################
## Checks if format of the kernel config file and sets the global variable
## 'FILE_IS_GZ' if it is in the .gz format.
################################################################################
find_file_format() {
    local kernel_config_file="$1"

    {
        echo "$kernel_config_file" | $GREP ".*\.gz$" 2>/dev/null 1>&2
    } && {
        FILE_IS_GZ=1
    } || {
        FILE_IS_GZ=0
    }
}

################################################################################
## Checks if the namespace-related kernel configs are enabled.
################################################################################
check_namespace_configs() {
    local kernel_config_file="$1"

    header "Namespace configs:"
    for config in $NAMESPACE_CONFIGS
    do
        check_if_enabled "CONFIG_$config" "$kernel_config_file"
    done
    info ""
}

################################################################################
## Checks if the cgroups-related kernel configs are enabled.
################################################################################
check_cgroup_configs() {
    local kernel_config_file="$1"

    header "Cgroup configs:"
    for config in $CGROUP_CONFIGS
    do
        check_if_enabled "CONFIG_$config" "$kernel_config_file"
    done
    info ""
}

################################################################################
## Checks if the other required kernel configs are enabled.
################################################################################
check_other_required_configs() {
    local kernel_config_file="$1"

    header "Other required configs:"
    for config in $OTHER_REQUIRED_CONFIGS
    do
        check_if_enabled "CONFIG_$config" "$kernel_config_file"
    done
    info ""
}

check_kernel_configs() {
    local user_provided_config_file="$1"

    info ""
    info "--------------------------------Kernel configuration--------------------------------"
    ## Get the kernel config file path.
    get_kernel_config_file "$user_provided_config_file"

    ## Check if the kernel config file is valid.
    if [ "$KERNEL_CONFIG_FILE" = "" ]
    then
        message="The file '/proc/config.gz' was not found.\n"
        message="$message\nTry loading the 'configs' module using the command:"
        message="$message 'sudo modprobe configs' and re-run\nthe script"
        message="$message 'check_ggc_dependencies' or invoke the script with"
        message="$message the option\n'--kernel-config-file <KERNEL_CONFIG_FILE>'."
        error "$message"
        add_to_container_errors "$message"
        info ""
        return
    else
        find_file_format "$KERNEL_CONFIG_FILE"
    fi

    ## Check if the required and optional kernel configs are enabled.
    info "Kernel config file: $KERNEL_CONFIG_FILE"
    info ""
    check_namespace_configs "$KERNEL_CONFIG_FILE"
    check_cgroup_configs "$KERNEL_CONFIG_FILE"
    check_other_required_configs "$KERNEL_CONFIG_FILE"

    if [ "$MISSING_CONFIGS_LIST" != "" ]
    then
        message="The kernel is missing the following required configs:\n"
        message="$message$MISSING_CONFIGS_LIST"
        add_to_dependency_container_failures "$message"
    fi
}
