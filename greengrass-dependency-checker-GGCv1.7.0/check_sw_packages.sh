OPENSSL_VERSION=""
JAVA_VERSION=""
REQUIRED_PYTHON_VERSION="2.7"
REQUIRED_NODEJS_VERSION="6.10"
REQUIRED_JAVA_VERSION="8"
MINIMUM_REQUIRED_OPENSSL_VERSION="1.0.1"

no_op() {
    :
}

################################################################################
## Checks if Python is installed on the device and if installed, whether its
## version meets the requirement for Greengrass lambdas.
################################################################################
check_python_version() {
    local python_version_info
    local python_version
    local message="Could not find the binary 'python$REQUIRED_PYTHON_VERSION'.\n"
    message="$message\nIf Python $REQUIRED_PYTHON_VERSION is installed on the"
    message="$message device, name the binary 'python$REQUIRED_PYTHON_VERSION'"
    message="$message and add its parent \ndirectory to the PATH environment variable."
    message="$message Python $REQUIRED_PYTHON_VERSION is required to execute Python"
    message="$message\nlambdas on Greengrass core."

    {
        ## Python reports the version to STDERR, so have to redirect STDERR to
        ## STDOUT and not capture the output in a variable.
        python$REQUIRED_PYTHON_VERSION --version >/dev/null 2>&1
    } || {
        wrap_warn "Python $REQUIRED_PYTHON_VERSION" "Not found"
        add_to_dependency_warnings "$message"
        return
    }

    python_version_info="$(python$REQUIRED_PYTHON_VERSION --version 2>&1)"
    python_version="$(echo $python_version_info | $CUT -d" " -f2)"
    if [ -n "$python_version_info" ]
    then
        wrap_good "Python version" "$python_version"
    else
        message="Failed to extract the Python version from the string:"
        message="$message '$python_version_info'"
        warn "$message"
        add_to_warnings "$message"
    fi
}

################################################################################
## Checks if NodeJS is installed on the device and if installed, whether its
## version is at least the minimum required version of NodeJS for Greengrass
## lambdas.
################################################################################
check_nodejs_version() {
    local node_version_info
    local node_version
    local message="Could not find the binary 'nodejs$REQUIRED_NODEJS_VERSION'.\n"
    message="$message\nIf NodeJS $REQUIRED_NODEJS_VERSION or later is installed"
    message="$message on the device, name the binary 'nodejs$REQUIRED_NODEJS_VERSION'"
    message="$message and\nadd its parent directory to the PATH environment variable."
    message="$message NodeJS $REQUIRED_NODEJS_VERSION or later is\nrequired to execute"
    message="$message NodeJS lambdas on Greengrass core."

    {
        node_version_info="$(nodejs$REQUIRED_NODEJS_VERSION --version 2>/dev/null)"
    } || {
        wrap_warn "NodeJS $REQUIRED_NODEJS_VERSION" "Not found"
        add_to_dependency_warnings "$message"
        return
    }

    node_version="$(echo ${node_version_info#v})"
    if [ -n "$node_version" ]
    then
        wrap_good "NodeJS version" "$node_version"
    else
        message="Failed to extract the NodeJS version from the string: '$node_version_info'"
        warn "$message"
        add_to_warnings "$message"
    fi
}

################################################################################
## Extracts the java version from the output of "java -version".
################################################################################
extract_java_version() {
    local java_version_info="$1"

    {
        JAVA_VERSION="$(echo "$java_version_info" | $HEAD -n 1 | $GREP -o "[_0-9\.]*")"
    } || {
        message="Failed to extract the Java version from the string: '$java_version_info'"
        warn "$message"
        add_to_warnings "$message"
    }
    
}

################################################################################
## Checks if Java is installed on the device and if installed, whether its
## version is at least the minimum required version of Java for Greengrass
## lambdas.
################################################################################
check_java_version() {
    local java_version_info
    local java_version
    local message="Could not find the binary 'java$REQUIRED_JAVA_VERSION'.\n"
    message="$message\nIf Java $REQUIRED_JAVA_VERSION or later is installed on"
    message="$message the device name the binary 'java$REQUIRED_JAVA_VERSION'"
    message="$message and add its\nparent directory to the PATH environment"
    message="$message variable. Java $REQUIRED_JAVA_VERSION or later is required"
    message="$message to\nexecute Java lambdas on Greengrass core."
    
    {
        ## Java reports the version to STDERR, so have to redirect STDERR to
        ## STDOUT and not capture the output in a variable.
        java$REQUIRED_JAVA_VERSION -version >/dev/null 2>&1
    } || {
        wrap_warn "Java $REQUIRED_JAVA_VERSION" "Not found"
        add_to_dependency_warnings "$message"
        return
    }

    java_version_info="$(java$REQUIRED_JAVA_VERSION -version 2>&1)"
    extract_java_version "$java_version_info"
    if [ -n "$JAVA_VERSION" ]
    then
        wrap_good "Java version" "$JAVA_VERSION"
    else
        message="Failed to extract the Java version from the string: '$java_version_info'"
        warn "$message"
        add_to_warnings "$message"
    fi
}

################################################################################
## Sorts and removes duplicates from the list of OpenSSL versions available on
## the device, sets the global variable 'OPENSSL_VERSION' if an OpenSSL version
## >= MINIMUM_REQUIRED_OPENSSL_VERSION is found.
################################################################################
get_openssl_version() {
    local openssl_versions="$1"

    openssl_unique_versions="$(echo "$openssl_versions" | $SORT | $UNIQ | $CUT -d" " -f2)"
    for version in $openssl_unique_versions
    do
        compare_versions "$version" "$MINIMUM_REQUIRED_OPENSSL_VERSION"
        if [ $GREATER_OR_EQUALS -eq 1 ]
        then
            OPENSSL_VERSION="$version"
            return
        fi
    done
}

################################################################################
## Finds the OpenSSL versions available on the device. The result may contain
## duplicates.
##
## For each file in the variable "cmd_output", prints the readable characters of
## the file using the "strings" command, greps the file contents for the pattern
## "OpenSSL <openssl_version>"
##
## alinux % echo "$cmd_output" | xargs strings | grep -Eo "## ## OpenSSL[0-9]+\.[0-9]+\.[0-9]*"
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 1.0.1
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 0.9.8
## OpenSSL 0.9.8
################################################################################
process_libssl_paths() {
    local cmd_output="$1"
    local openssl_versions

    {
        openssl_versions="$(echo "$cmd_output" | $XARGS $STRINGS | \
        $GREP -Eo "OpenSSL [0-9]+\.[0-9]+\.[0-9]*")"
    } && {
        get_openssl_version "$openssl_versions"
    } || {
        no_op
        ## Ignore the error. The error will be detected in the parent functions
        ## since the global variable OPENSSL_VERSION will be an empty string.
    }
}

################################################################################
## Rerieves the abolute paths of the candidate libssl .so files by searching
## recursively in /lib, /usr/lib and /usr/local/lib (the standard paths where
## shared object files are found).
##
## alinux % find /usr*/lib* /lib* -name "libssl*" | grep "\.so"
## /usr/lib/libssl.so.0.9.8e
## /usr/lib/libssl.so.10
## /usr/lib/libssl.so.1.0.1k
## /usr/lib/libssl.so.1.0.0
## /usr/lib/libssl3.so
## /usr/lib/libssl.so.6
## /usr/lib64/libssl.so.0.9.8e
## /usr/lib64/libssl.so.10
## /usr/lib64/libssl.so.1.0.1k
## /usr/lib64/libssl3.so
## /usr/lib64/libssl.so.6
################################################################################
get_openssl_version_using_find() {
    local find_output

    local search_paths="/usr/lib* /lib*"
    if [ -d "/usr/local/bin" ]
    then
        search_paths="$search_paths /usr/local/bin"
    fi

    {
        find_output="$($FIND $search_paths -name "libssl*" | $GREP "\.so")"
    } && {
        process_libssl_paths "$find_output"
    } || {
        no_op
        ## Ignore the error. The error will be detected in the calling function
        ## since the global variable OPENSSL_VERSION will be an empty string.
    }
}

################################################################################
## Retrieves the list of candidate libssl paths using the 'ldconfig' command.
##
## Prints the lists of libraries stored in the cache, filters the results by
## 'libssl' and retrieves the absolute paths of candidate libssl .so files by
## retrieving the fourth field delimited by space:
## 
## alinux % ldconfig -p | grep libssl
## libssl3.so (libc6,x86-64) => /usr/lib64/libssl3.so
## libssl3.so (libc6) => /usr/lib/libssl3.so
## libssl.so.10 (libc6,x86-64) => /usr/lib64/libssl.so.10
## libssl.so.10 (libc6) => /usr/lib/libssl.so.10
## libssl.so.6 (libc6,x86-64) => /usr/lib64/libssl.so.6
## libssl.so.6 (libc6) => /usr/lib/libssl.so.6
##
## alinux % ldconfig -p | grep libssl | cut -d" " -f 4
## /usr/lib64/libssl3.so
## /usr/lib/libssl3.so
## /usr/lib64/libssl.so.10
## /usr/lib/libssl.so.10
## /usr/lib64/libssl.so.6
## /usr/lib/libssl.so.6
################################################################################
get_openssl_version_using_ldconfig() {
    local ldconfig_output

    {
        ldconfig_output="$(ldconfig -p 2>/dev/null | $GREP libssl)"
    } && {
        ldconfig_output="$(echo "$ldconfig_output" | $CUT -d" " -f 4)"
        process_libssl_paths "$ldconfig_output"
    } || {
        no_op
        ## Ignore the error. The error will be detected in the calling function
        ## since the global variable OPENSSL_VERSION will be an empty string.
    }
}

################################################################################
## Checks if the version of OpenSSL on the device is at least the minimum
## required version for the Over The Air(OTA) agent.
################################################################################
check_openssl_version() {
    local message

    ## First, try to get the version of OpenSSL using the 'ldconfig' command.
    get_openssl_version_using_ldconfig

    ## If the global variable 'OPENSSL_VERSION' is an empty string, fall back to
    ## finding the OpenSSL version by searching through the shared libraries
    ## using the 'find' command.
    if [ "$OPENSSL_VERSION" = "" ]
    then
        get_openssl_version_using_find
    fi

    ## Warn, if the global variable is still an empty string.
    if [ "$OPENSSL_VERSION" = "" ]
    then
        wrap_warn "OpenSSL (>= $MINIMUM_REQUIRED_OPENSSL_VERSION)" "Not found"
        message="Could not find OpenSSL version >= $MINIMUM_REQUIRED_OPENSSL_VERSION"
        message="$message on the device after searching through the\nstandard paths"
        message="$message : /lib, /usr/lib and /usr/local/lib.\n"
        message="$message\nThe Over The Air(OTA) agent requires OpenSSL version"
        message="$message $MINIMUM_REQUIRED_OPENSSL_VERSION or later to run."
        add_to_dependency_warnings "$message"
        return
    fi

    wrap_good "OpenSSL version" "$OPENSSL_VERSION"
}

################################################################################
## Checks if a command is present on the device.
################################################################################
check_if_command_present() {
    local cmd="$1"
    local message="The '$cmd' command was not found on the device. '$cmd'"
    message="$message is required if the\nOver The Air(OTA) agent is used."

    {
        command -v $cmd 2>/dev/null 1>&2 && wrap_good "$cmd" "Present"
    } || {
        wrap_warn "$cmd" "Not found"
        add_to_dependency_warnings "$message"
    }
}

################################################################################
## Checks if the software packages and commands required for the Over The
## Air(OTA) agent are present on the device.
################################################################################
check_ota_agent_req() {
    check_openssl_version
    check_if_command_present "wget"
    check_if_command_present "realpath"
    check_if_command_present "tar"
    check_if_command_present "readlink"
    check_if_command_present "basename"
    check_if_command_present "dirname"
    check_if_command_present "pidof"
    check_if_command_present "df"
    check_if_command_present "grep"
    check_if_command_present "umount"
}

check_sw_packages() {
    info "----------------------------Commands and software packages--------------------------"
    check_python_version
    check_nodejs_version
    check_java_version
    check_ota_agent_req
}
