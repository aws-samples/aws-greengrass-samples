## Log levels, in the order of increasing verbosity
readonly FATAL=1
readonly ERROR=2
readonly INFO=3
readonly WARN=4
readonly DEBUG=5

## ANSI escape codes for colors
readonly RED="\033[0;31m"
readonly BOLD_RED="\033[1;31m"
readonly BLUE="\033[1;34m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly WHITE="\033[0;37m"
readonly CYAN="\033[0;36m"
readonly WHITE_UNDERLINE="\033[4;37m"
readonly NC="\033[0m"    # No color

## Default verbosity
VERBOSITY=$WARN

## Exit code for the script
SCRIPT_EXIT_CODE=0

NOTES=""
WARNINGS=""
ERRORS=""
DEPENDENCY_WARNINGS=""
DEPENDENCY_FAILURES=""

CONTAINER_ERRORS=""
DEPENDENCY_CONTAINER_WARNINGS=""
DEPENDENCY_CONTAINER_FAILURES=""

NOTES_COUNT=0
WARNINGS_COUNT=0
ERRORS_COUNT=0
DEPENDENCY_WARNINGS_COUNT=0
DEPENDENCY_FAILURES_COUNT=0

CONTAINER_ERRORS_COUNT=0
DEPENDENCY_CONTAINER_WARNINGS_COUNT=0
DEPENDENCY_CONTAINER_FAILURES_COUNT=0

validate_and_set_verbosity() {
    local verbosity="$1"

    case "$verbosity" in
        FATAL )
            VERBOSITY=$FATAL
            ;;

        ERROR )
            VERBOSITY=$ERROR
            ;;

        INFO )
            VERBOSITY=$INFO
            ;;

        WARN )
            VERBOSITY=$WARN
            ;;

        DEBUG )
            VERBOSITY=$DEBUG
            ;;

        * )
            fatal "Unknown --log-level '$verbosity'."
            fatal "--log-level should be one of:"
            fatal "FATAL, ERROR, INFO, WARN and DEBUG"
            exit 1
            ;;
    esac
}

set_verbosity() {
    local verbosity="$1"

    validate_and_set_verbosity "$verbosity"
    if [ $VERBOSITY -eq $DEBUG ]
    then
        set -x
    fi
}

log() {
    local log_level="$1"
    local color="$2"
    local message="$3"
    local new_line="$4"

    if [ $log_level -le $VERBOSITY ]
    then
        $PRINTF "${color}$message${NC}"
        if [ $new_line -eq 1 ]
        then
            $PRINTF "\n"
        fi
    fi
}

label() {
    local message="$1"
    local log_level="$2"
    log $log_level $CYAN "$message" 0
}

header() {
    local message="$1"
    log $INFO $BLUE "$message" 1
}

underline() {
    local message="$1"
    local log_level="$2"
    log $log_level $WHITE_UNDERLINE "$message" 0
}

fatal() {
    local message="$1"
    log $FATAL $BOLD_RED "$message" 1
    SCRIPT_EXIT_CODE=1
}

error() {
    local message="$1"
    log $ERROR $RED "$message" 1
    SCRIPT_EXIT_CODE=1
}

optional_error() {
    local message="$1"
    log $ERROR $RED "$message" 1
}

optional_fatal() {
    local message="$1"
    log $FATAL $BOLD_RED "$message" 1
}

debug() {
    local message="$1"
    log $DEBUG $WHITE "$message" 1
}

info() {
    local message="$1"
    log $INFO $WHITE "$message" 1
}

success() {
    local message="$1"
    log $INFO $GREEN "$message" 1
}

warn() {
    local message="$1"
    log $WARN $YELLOW "$message" 1
}

wrap_good() {
    label "$1: " $INFO
    success "$2"
}

wrap_warn() {
    label "$1: " $WARN
    warn "$2"
}

wrap_bad() {
    label "$1: " $FATAL
    fatal "$2"
}

wrap_optional_bad() {
    label "$1: " $FATAL
    optional_fatal "$2"
}

wrap_info() {
    label "$1: " $INFO
    info "$2"
}

add_to_notes() {
    local message="$1"

    NOTES_COUNT=$($EXPR $NOTES_COUNT + 1)
    NOTES="$NOTES\n$NOTES_COUNT. $message\n"
}

add_to_errors() {
    local message="$1"

    SCRIPT_EXIT_CODE=1
    ERRORS_COUNT=$($EXPR $ERRORS_COUNT + 1)
    ERRORS="$ERRORS\n$ERRORS_COUNT. $message\n"
}

add_to_warnings() {
    local message="$1"

    WARNINGS_COUNT=$($EXPR $WARNINGS_COUNT + 1)
    WARNINGS="$WARNINGS\n$WARNINGS_COUNT. $message\n"
}

add_to_dependency_warnings() {
    local message="$1"

    DEPENDENCY_WARNINGS_COUNT=$($EXPR $DEPENDENCY_WARNINGS_COUNT + 1)
    DEPENDENCY_WARNINGS="$DEPENDENCY_WARNINGS\n$DEPENDENCY_WARNINGS_COUNT. $message\n"
}

add_to_dependency_failures() {
    local message="$1"

    SCRIPT_EXIT_CODE=1
    DEPENDENCY_FAILURES_COUNT=$($EXPR $DEPENDENCY_FAILURES_COUNT + 1)
    DEPENDENCY_FAILURES="$DEPENDENCY_FAILURES\n$DEPENDENCY_FAILURES_COUNT. $message\n"
}

add_to_container_errors() {
    local message="$1"

    CONTAINER_ERRORS_COUNT=$($EXPR $CONTAINER_ERRORS_COUNT + 1)
    CONTAINER_ERRORS="$CONTAINER_ERRORS\n$CONTAINER_ERRORS_COUNT. $message\n"
}

add_to_dependency_container_warnings() {
    local message="$1"

    DEPENDENCY_CONTAINER_WARNINGS_COUNT=$($EXPR $DEPENDENCY_CONTAINER_WARNINGS_COUNT + 1)
    DEPENDENCY_CONTAINER_WARNINGS="$DEPENDENCY_CONTAINER_WARNINGS\n$DEPENDENCY_CONTAINER_WARNINGS_COUNT. $message\n"
}

add_to_dependency_container_failures() {
    local message="$1"

    DEPENDENCY_CONTAINER_FAILURES_COUNT=$($EXPR $DEPENDENCY_CONTAINER_FAILURES_COUNT + 1)
    DEPENDENCY_CONTAINER_FAILURES="$DEPENDENCY_CONTAINER_FAILURES\n$DEPENDENCY_CONTAINER_FAILURES_COUNT. $message\n"
}

print_results() {
    local message
    local ggc_version="$1"
    local missing_dependencies_count=0

    info ""
    info "------------------------------------Results-----------------------------------------"
    if [ $NOTES_COUNT -ne 0 ]
    then
        underline "Note:" $INFO
        info "$NOTES"
    fi

    if [ $WARNINGS_COUNT -ne 0 ]
    then
        underline "Warnings:" $WARN
        warn "$WARNINGS"
    fi

    if [ $ERRORS_COUNT -ne 0 ]
    then
        underline "Errors:" $ERROR
        error "$ERRORS"
    fi

    if [ $DEPENDENCY_WARNINGS_COUNT -ne 0 ]
    then
        underline "Missing optional dependencies:" $WARN
        warn "$DEPENDENCY_WARNINGS"
    fi

    if [ $DEPENDENCY_FAILURES_COUNT -ne 0 ]
    then
        underline "Missing required dependencies:" $FATAL
        fatal "$DEPENDENCY_FAILURES"
    fi

    if [ $CONTAINER_ERRORS_COUNT -ne 0 ] ||
        [ $DEPENDENCY_CONTAINER_WARNINGS_COUNT -ne 0 ] || 
        [ $DEPENDENCY_CONTAINER_FAILURES_COUNT -ne 0 ]
    then
        underline "(Optional) Greengrass container dependencies\n" $WARN
    fi

    if [ $CONTAINER_ERRORS_COUNT -ne 0 ]
    then
        underline "Errors:" $WARN
        warn "$CONTAINER_ERRORS"
    fi

    if [ $DEPENDENCY_CONTAINER_WARNINGS_COUNT -ne 0 ]
    then
        underline "Missing optional dependencies:" $WARN
        warn "$DEPENDENCY_CONTAINER_WARNINGS"
    fi

    if [ $DEPENDENCY_CONTAINER_FAILURES_COUNT -ne 0 ]
    then
        underline "Missing required dependencies:" $WARN
        warn "$DEPENDENCY_CONTAINER_FAILURES"
    fi

    underline "Supported lambda isolation modes:\n" $INFO

    if [ $SCRIPT_EXIT_CODE -ne 0 ]
    then
        wrap_bad "No Container" "Not supported"
    else
        wrap_good "No Container" "Supported"
    fi

    if [ $SCRIPT_EXIT_CODE -ne 0 ] ||
        [ $CONTAINER_ERRORS_COUNT -ne 0 ] ||
        [ $DEPENDENCY_CONTAINER_FAILURES_COUNT -ne 0 ]
    then
        wrap_warn "Greengrass Container" "Not supported"
    else 
        wrap_good "Greengrass Container" "Supported"
    fi

    info ""
    info "----------------------------------Exit status---------------------------------------"
    if [ $SCRIPT_EXIT_CODE -ne 0 ]
    then
        message="Either the script failed to verify all dependencies or the device"
        message="$message is missing one or\nmore of the required"
        message="$message dependencies for Greengrass version $ggc_version.\n"
        message="$message\nRefer to the 'Errors' and 'Missing required dependencies'"
        message="$message sections under 'Results'\nfor details."
        fatal "$message"
    else  
        message="You can now proceed to installing the Greengrass core $ggc_version"
        message="$message software on the device.\nPlease reach out to the AWS"
        message="$message Greengrass support if issues arise.\n"
        info "$message"
    fi

    exit $SCRIPT_EXIT_CODE
}
