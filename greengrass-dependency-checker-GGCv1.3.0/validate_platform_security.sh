HARDLINKS_PROTECTION_CONFIG="fs.protected_hardlinks"
SYMLINKS_PROTECTION_CONFIG="fs.protected_symlinks"
INSECURE_MODE=0

MESSAGE="Insecure OS configuration detected - hardlinks/symlinks protection is not"
MESSAGE="$MESSAGE enabled\non the device. With the current setting, Greengrass"
MESSAGE="$MESSAGE core can be run only in the\ninsecure mode (with the -i flag),"
MESSAGE="$MESSAGE which is highly discouraged. Check the official\nGreengrass"
MESSAGE="$MESSAGE documentation to fix this."
MESSAGE="$MESSAGE"

################################################################################
## Checks if hardlinks protection is enabled on the device.
################################################################################
verify_hardlinks_protection() {
    {
        $SYSCTL $HARDLINKS_PROTECTION_CONFIG | $GREP "$HARDLINKS_PROTECTION_CONFIG = 1"
    } && {
        wrap_good "Hardlinks_protection" "Enabled"
    } || {
        wrap_warn "Hardlinks protection" "Not enabled"
        INSECURE_MODE=1
    }
}

################################################################################
## Checks if symlinks protection is enabled on the device.
################################################################################
verify_symlinks_protection() {
    {
        $SYSCTL $SYMLINKS_PROTECTION_CONFIG | $GREP "$SYMLINKS_PROTECTION_CONFIG = 1"
    } && {
        wrap_good "Symlinks protection" "Enabled"
    } || {
        wrap_warn "Symlinks protection" "Not enabled"
        INSECURE_MODE=1
    }
}

################################################################################
## Greengrass requires hardlinks and symlinks protection enabled.
## If not enabled, Greengrass can only be run in the insecure mode using the '-i'
## flag, but this is highly discouraged:
##
## sudo ./greengrassd -i start
################################################################################
validate_platform_security() {
    info ""
    info "---------------------------------Platform security----------------------------------"

    verify_hardlinks_protection
    verify_symlinks_protection

    if [ $INSECURE_MODE -eq 1 ]
    then
        add_to_warnings "$MESSAGE"
        return
    fi
}

