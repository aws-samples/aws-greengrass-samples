################################################################################
## Extracts the major version from a given semantic version string and sets the
## global variable 'MAJOR_VERSION' with the value.
################################################################################
get_major_version() {
    local full_version="$1"

    MAJOR_VERSION="${full_version%%.*}"
}

################################################################################
## Extracts the minor version from a given semantic version string and sets the
## global variable 'MINOR_VERSION' with the value.
################################################################################
get_minor_version() {
    local full_version="$1"

    minor_version="${full_version#*.}"
    MINOR_VERSION="${minor_version%%.*}"
}

################################################################################
## Extracts the patch version from a given semantic version string and sets the
## global variable 'PATCH' with the value.
################################################################################
get_patch() {
    local full_version="$1"

    PATCH=${full_version##*.*.}
    if [ "$full_version" = "$PATCH" ]
    then
        PATCH=0
    fi
}

################################################################################
## Compares two semantic version strings and sets the global variable
## GREATER_OR_EQUALS, if the first version is greater than or equal to the
## second version.
################################################################################
compare_versions() {
    local left_version="$1"
    local right_version="$2"

    ## Compare major versions
    get_major_version "$left_version"
    local left_major="$MAJOR_VERSION"
    get_major_version "$right_version"
    local right_major="$MAJOR_VERSION"

    if [ "$left_major" -gt "$right_major" ]
    then
        GREATER_OR_EQUALS=1
        return
    elif [ "$left_major" -lt "$right_major" ]
    then
        GREATER_OR_EQUALS=0
        return
    fi

    ## Compare minor versions
    get_minor_version "$left_version"
    local left_minor="$MINOR_VERSION"
    get_minor_version "$right_version"
    local right_minor="$MINOR_VERSION"

    if [ "$left_minor" -gt "$right_minor" ]
    then
        GREATER_OR_EQUALS=1
        return
    elif [ "$left_minor" -lt "$right_minor" ]
    then
        GREATER_OR_EQUALS=0
        return
    fi

    ## Compare patch versions
    get_patch "$left_version"
    local left_patch="$PATCH"
    get_patch "$right_version"
    local right_patch="$PATCH"

    if [ "$left_patch" -gt "$right_patch" ]
    then
        GREATER_OR_EQUALS=1
        return
    elif [ "$left_patch" -lt "$right_patch" ]
    then
        GREATER_OR_EQUALS=0
        return
    fi

    GREATER_OR_EQUALS=1
}

################################################################################
## Given a message enclosed by parathesis, this function removes the parathesis
## around the message.
## Eg: Given "(GNU libc)", the function returns "GNU libc".
################################################################################
remove_parantheses() {
    local message="$1"

    ## Remove the open parathesis from the beginning of the message
    message="${message#\(}"

    ## Remove the close parathesis from the end of the message
    message="${message%%)}"

    STRING_WITHOUT_PARATHESIS="$message"
}

################################################################################
## Removes all charaters from a version string, except for major and minor
## versions.
##
## Reference for substring removal using %% and #:
## http://wiki.bash-hackers.org/syntax/pe#substring_removal
################################################################################
sanitize_version_string() {
    local major_version
    local minor_version
    local full_version="$1"

    ## Extract the major and minor version from the full version.
    ## Eg: 4.1.3+ is converted to 4.1.3
    major_version="${full_version%%.*}"

    minor_version="${full_version#$major_version.}"
    minor_version="${minor_version%%.*}"

    patch_version="${full_version##$major_version.$minor_version.}"
    if [ "$full_version" = "$patch_version" ]
    then
        patch_version="0"
    else
        # Remove dot "." if in front of patch version
        patch_version="${patch_version#.}"
        # Remove everything after the patch version number
        patch_version="${patch_version%%[^0-9]*}"
    fi

    SANITIZED_VERSION_STRING="$major_version.$minor_version.$patch_version"
}

lower_case_string() {
    local upper="$1"

    LOWER_CASE_STRING=$(echo ${upper} | $AWK '{print tolower($0)}')
}

