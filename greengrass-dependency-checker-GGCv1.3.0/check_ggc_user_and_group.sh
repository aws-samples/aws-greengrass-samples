GGC_USER="ggc_user"
GGC_GROUP="ggc_group"

USER_CONFIG_FILE="/etc/passwd"
GROUP_CONFIG_FILE="/etc/group"

################################################################################
## To run the Greengrass core, the device must have a user named 'ggc_user'
################################################################################
check_ggc_user_exists() {
    local message

    {
        $GREP "^$GGC_USER:" "$USER_CONFIG_FILE" 1>/dev/null 2>&1
    } && {
        wrap_good "$GGC_USER" "Present"
    } || {
        message="User $GGC_USER, required to run Greengrass core, is not"
        message="$message present on the device.\nRefer to the official Greengrass"
        message="$message documentation to fix this."
        wrap_bad "User $GGC_USER" "Not found"
        add_to_fatals "$message"
    }
}

################################################################################
## To run the Greengrass core, the device must have a group named 'ggc_group'
################################################################################
check_ggc_group_exists() {
    local message

    {
        $GREP "^$GGC_GROUP:" "$GROUP_CONFIG_FILE" 1>/dev/null 2>&1
    } && {
        wrap_good "$GGC_GROUP" "Present"
    } || {
        message="Group $GGC_GROUP, required to run Greengrass core, is not"
        message="$message present on the device.\nRefer to the official Greengrass"
        message="$message documentation to fix this."
        wrap_bad "Group $GGC_GROUP" "Not found"
        add_to_fatals "$message"
    }
}

check_ggc_user_and_group_exist() {
    info ""
    info "-----------------------------------User and group-----------------------------------"
    check_ggc_user_exists
    check_ggc_group_exists
}