JAVA_VERSION=""
REQUIRED_PYTHON2_VERSION="2.7"
REQUIRED_PYTHON37_VERSION="3.7"
REQUIRED_PYTHON38_VERSION="3.8"
REQUIRED_NODEJS_VERSION="12.x"
REQUIRED_JAVA_VERSION="8"

no_op() {
    :
}

################################################################################
## Checks if Python 2.7 is installed on the device and if installed, whether its
## version meets the requirement for Greengrass lambdas.
################################################################################
check_python2_version() {
    local python_version_info
    local python_version
    local message="Could not find the binary 'python$REQUIRED_PYTHON2_VERSION'.\n"
    message="$message\nIf Python $REQUIRED_PYTHON2_VERSION is installed on the"
    message="$message device, name the binary 'python$REQUIRED_PYTHON2_VERSION'"
    message="$message and add its parent \ndirectory to the PATH environment variable."
    message="$message Python $REQUIRED_PYTHON2_VERSION is required to execute Python 2.7"
    message="$message\nlambdas on Greengrass core."

    {
        ## Python reports the version to STDERR, so have to redirect STDERR to
        ## STDOUT and not capture the output in a variable.
        python$REQUIRED_PYTHON2_VERSION --version >/dev/null 2>&1
    } || {
        wrap_warn "Python $REQUIRED_PYTHON2_VERSION" "Not found"
        add_to_dependency_warnings "$message"
        return
    }

    python_version_info="$(python$REQUIRED_PYTHON2_VERSION --version 2>&1)"
    python_version="$(echo $python_version_info | $CUT -d" " -f2)"
    if [ -n "$python_version_info" ]
    then
        wrap_good "Python 2.7 version" "$python_version"
    else
        message="Failed to extract the Python 2.7 version from the string:"
        message="$message '$python_version_info'"
        warn "$message"
        add_to_warnings "$message"
    fi
}

################################################################################
## Checks if either Python 3.7 or 3.8 is installed on the device and if installed,
## whether its version meets the requirement for Greengrass lambdas.
################################################################################
check_python3_version() {
    local python_version_info
    local python_version
    local python37_IS_FOUND=false
    local python38_IS_FOUND=false

    # Python3.7 check
    local message="Could not find the binary 'python$REQUIRED_PYTHON37_VERSION'.\n"
    message="$message\nIf Python $REQUIRED_PYTHON37_VERSION is installed on the"
    message="$message device, name the binary 'python$REQUIRED_PYTHON37_VERSION'"
    message="$message and add its parent \ndirectory to the PATH environment variable."
    message="$message Python $REQUIRED_PYTHON37_VERSION is required to execute Python 3.7"
    message="$message\nlambdas on Greengrass core."

    {
        ## Python reports the version to STDERR, so have to redirect STDERR to
        ## STDOUT and not capture the output in a variable.
        python$REQUIRED_PYTHON37_VERSION --version >/dev/null 2>&1 && python37_IS_FOUND=true
    } || {
        wrap_warn "Python $REQUIRED_PYTHON37_VERSION" "Not found"
        add_to_dependency_warnings "$message"
    }

    # Python3.8 check
    message="Could not find the binary 'python$REQUIRED_PYTHON38_VERSION'.\n"
    message="$message\nIf Python $REQUIRED_PYTHON38_VERSION is installed on the"
    message="$message device, name the binary 'python$REQUIRED_PYTHON38_VERSION'"
    message="$message and add its parent \ndirectory to the PATH environment variable."
    message="$message Python $REQUIRED_PYTHON38_VERSION is required to execute Python 3.8"
    message="$message\nlambdas on Greengrass core."
    {
        ## Python reports the version to STDERR, so have to redirect STDERR to
        ## STDOUT and not capture the output in a variable.
        python$REQUIRED_PYTHON38_VERSION --version >/dev/null 2>&1 && python38_IS_FOUND=true
    } || {
        wrap_warn "Python $REQUIRED_PYTHON38_VERSION" "Not found"
        add_to_dependency_warnings "$message"
    }

    if [ "$python37_IS_FOUND" = false ] && [ "$python38_IS_FOUND" = false ]
    then
      return
    fi

    ## Python3.7
    if [ "$python37_IS_FOUND" = true ]
    then
      python_version_info="$(python$REQUIRED_PYTHON37_VERSION --version 2>&1)"
      python_version="$(echo $python_version_info | $CUT -d" " -f2)"
      if [ -n "$python_version_info" ]
      then
          wrap_good "Python 3.7 version" "$python_version"
      else
          message="Failed to extract the Python 3.7 version from the string:"
          message="$message '$python_version_info'"
          warn "$message"
          add_to_warnings "$message"
      fi
    fi

    ## Python3.8
    if [ "$python38_IS_FOUND" = true ]
    then
      python_version_info="$(python$REQUIRED_PYTHON38_VERSION --version 2>&1)"
      python_version="$(echo $python_version_info | $CUT -d" " -f2)"
      if [ -n "$python_version_info" ]
      then
          wrap_good "Python 3.8 version" "$python_version"
      else
          message="Failed to extract the Python 3.8 version from the string:"
          message="$message '$python_version_info'"
          warn "$message"
          add_to_warnings "$message"
      fi
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
    local node_major_version
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
    node_major_version="$(echo ${node_version%.*.*})"
    if [ -n "$node_version" ]
    then
      if [ "$node_major_version" = ${REQUIRED_NODEJS_VERSION%.*} ]
      then
        wrap_good "NodeJS version" "$node_version"
      else
        message="Expected NodeJS $REQUIRED_NODEJS_VERSION, found NodeJS $node_version"
        warn "$message"
        add_to_warnings "$message"
      fi
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
    message="$message to\nexecute Java lambdas as well as stream management"
    message="$message features on Greengrass core."

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
    check_if_command_present "mv"
    check_if_command_present "gzip"
    check_if_command_present "mkdir"
    check_if_command_present "rm"
    check_if_command_present "ln"
    check_if_command_present "cat"
    check_if_command_present "cut"
    check_if_command_present "/bin/bash"
}

check_sw_packages() {
    info "----------------------------Commands and software packages--------------------------"
    check_python2_version
    check_python3_version
    check_nodejs_version
    check_java_version
    check_ota_agent_req
}
