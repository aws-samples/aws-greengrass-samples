GGC_USER="ggc_user"
GGC_GROUP="ggc_group"

USER_CONFIG_FILE="/etc/passwd"
GROUP_CONFIG_FILE="/etc/group"

###################################################################################
## To run the Greengrass core, the device must either have a user named 'ggc_user'
## or override the group-level default uid.
###################################################################################
check_ggc_user_exists() {
    local message

    {
        $GREP "^$GGC_USER:" "$USER_CONFIG_FILE" 2>/dev/null 1>&2
    } && {
        wrap_good "$GGC_USER" "Present"
    } || {
        message="User $GGC_USER, required to run Greengrass core, is not"
        message="$message present on the device.\nRefer to the official Greengrass"
        message="$message documentation to install $GGC_USER or override the\n"
        message="${message}\"Uid\" field of your Greengrass Group's"
        message="$message DefaultFunctionExecutionConfig before deploying."
        wrap_warn "User $GGC_USER" "Not found"
        add_to_dependency_warnings "$message"
    }
}

#####################################################################################
## To run the Greengrass core, the device must either have a group named 'ggc_group'
## or override group-level default gid.
#####################################################################################
check_ggc_group_exists() {
    local message

    {
        $GREP "^$GGC_GROUP:" "$GROUP_CONFIG_FILE" 2>/dev/null 1>&2
    } && {
        wrap_good "$GGC_GROUP" "Present"
    } || {
        message="Group $GGC_GROUP, required to run Greengrass core, is not"
        message="$message present on the device.\nRefer to the official Greengrass"
        message="$message documentation to install $GGC_GROUP or override the\n"
        message="${message}\"Gid\" field of your Greengrass Group's"
        message="$message DefaultFunctionExecutionConfig before deploying."
        wrap_warn "Group $GGC_GROUP" "Not found"
        add_to_dependency_warnings "$message"
    }
}

check_ggc_user_and_group_exist() {
    info ""
    info "-----------------------------------User and group-----------------------------------"
    check_ggc_user_exists
    check_ggc_group_exists
}
