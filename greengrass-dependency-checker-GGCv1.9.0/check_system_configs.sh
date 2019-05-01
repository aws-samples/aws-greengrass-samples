MINIMUM_REQUIRED_KERNEL_VERSION="3.17"
MINIMUM_RECOMMENDED_KERNEL_VERSION="4.4"
MINIMUM_REQUIRED_LIBC_VERSION="2.14"

C_LIBRARY=""
C_LIBRARY_VERSION=""

################################################################################
## Prints the kernel architecture.
##
## This is not a check, just diagnostic information that a customer can submit
## to Greengrass support, in case Greengrass fails to run on the host device.
##
## This script does not check if a Greengrass binary is available for this
## architecture.
################################################################################
get_kernel_architecture() {
    local message

    local kernel_architecture="$($UNAME -m)"
    wrap_info "Kernel architecture" "$kernel_architecture"
}

################################################################################
## Checks if the init process on the host device is 'systemd'
################################################################################
check_if_systemd() {
    init_process="$1"

    {
        systemd_used="$(echo "$init_process" | $GREP -o systemd)"
    } && {
        message="It looks like the kernel uses 'systemd' as the init process"
        message="$message. Be sure to set the\n'useSystemd' field in the file"
        message="$message 'config.json' to 'yes' when configuring Greengrass"
        message="$message core."
        add_to_notes "$message"
    } || {
        message="It looks like the kernel does NOT use 'systemd' as the init process"
        message="$message. Be sure to set\nthe 'useSystemd' field in the file"
        message="$message 'config.json' to 'no' when configuring Greengrass\ncore."
        add_to_notes "$message"
    }
}

################################################################################
## Prints the init process path for the kernel in use.
##
## This is not a check, just information that the customer can use when configuring
## Greengrass core. If the init process is 'systemd', then the 'useSystemd' field
## should be set to 'yes' in the file 'config.json' when configuring Greengrass core.
################################################################################
get_init_process() {
    local init_process
    local systemd_used

    ## Find the path of the executable running as PID 1
    ##
    ## Sample outputs:
    ## root@OpenWrt3-:~# readlink /proc/1/exe
    ## /sbin/procd
    ##
    ## ubuntu:~$ sudo readlink /proc/1/exe
    ## /lib/systemd/systemd
    ##
    ## alinux % sudo readlink /proc/1/exe
    ## /sbin/init
    { #try
        init_process="$($READLINK /proc/1/exe 2>/dev/null)" && $TEST -n "$init_process"
    } || { #catch
        error "Failed to find the init process on the host!"
        add_to_errors "Failed to find the init process on the host"
        return
    }

    wrap_info "Init process" "$init_process"
    check_if_systemd "$init_process"
}

################################################################################
## Checks if the kernel version meets the Greengrass core requirements.
################################################################################
check_kernel_version() {

    ## Get the kernel version
    local kernel_version="$($UNAME -r)"

    ## Extract the major and minor version of the kernel from the output
    sanitize_version_string "$kernel_version"
    kernel_version="$SANITIZED_VERSION_STRING"

    compare_versions "$kernel_version" "$MINIMUM_REQUIRED_KERNEL_VERSION"
    if [ $GREATER_OR_EQUALS -ne 1 ]
    then
        local message="Greengrass must run on a Linux kernel with"
        message="$message version $MINIMUM_REQUIRED_KERNEL_VERSION or greater."
        message="$message The Linux\nkernel version on the device is"
        message="$message $kernel_version."
        wrap_bad "Kernel version" "$kernel_version"
        add_to_dependency_failures "$message"
        return
    fi

    compare_versions "$kernel_version" "$MINIMUM_RECOMMENDED_KERNEL_VERSION"
    if [ $GREATER_OR_EQUALS -ne 1 ]
    then
        local message="Greengrass runs most optimally with a Linux kernel"
        message="$message version $MINIMUM_RECOMMENDED_KERNEL_VERSION or greater."
        message="$message The Linux\nkernel version on the device is"
        message="$message $kernel_version."
        wrap_warn "Kernel version" "$kernel_version"
        add_to_dependency_warnings "$message"
        return
    fi

    wrap_info "Kernel version" "$kernel_version"
}

################################################################################
## Extracts the C library info from the output of 'ldd --version'.
##
## Sample ldd output:
## ldd (Ubuntu GLIBC 2.23-0ubuntu9) 2.23
## Copyright (C) 2016 Free Software Foundation, Inc.
## This is free software; see the source for copying conditions.  There is NO
## warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## Written by Roland McGrath and Ulrich Drepper.
##
## Given the above output as a parameter, this function returns:
## C_LIBRARY="Ubuntu GLIBC 2.23-0ubuntu9"
## C_LIBRARY_VERSION="2.23"
################################################################################
parse_ldd_output() {
    local libc_info="$1"

    ## Extract the first line from the output
    local ldd_output="$(echo "$libc_info" | $HEAD -n 1)"

    ## Find the C library - find a string enclosed in parathesis
    {
        c_library="$(echo "$ldd_output" | $GREP -o '(.*)')"
    } && {
        remove_parantheses "$c_library"
        C_LIBRARY="$STRING_WITHOUT_PARATHESIS"
    } || {
        ## Do not log the error here. The error will be caught in the parent
        ## function by testing for an empty C_LIBRARY.
        return
    }

    ## Extract the C library version - find the string after the last space on
    ## line.
    {
        C_LIBRARY_VERSION="$(echo "$ldd_output" | $GREP -o '[^ ]*$')"
    } || {
        ## Do not log the error here. The error will be caught in the parent
        ## function by testing for an empty C_LIBRARY_VERSION.
        return
    }
}

################################################################################
## Extracts the C library info from the output of executing libc.so.6
##
## ubuntu@dev-box:~$ find /lib* -name libc.so.6
## /lib/x86_64-linux-gnu/libc.so.6
##
## ubuntu@dev-box:~$ /lib/x86_64-linux-gnu/libc.so.6
## GNU C Library (Ubuntu GLIBC 2.23-0ubuntu9) stable release version 2.23, by Roland McGrath et al.
## Copyright (C) 2016 Free Software Foundation, Inc.
## ...
## ...
##
## Given the sample output above, this function would return:
## C_LIBRARY="Ubuntu GLIBC 2.23-0ubuntu9"
## C_LIBRARY_VERSION="2.23"
################################################################################
parse_libc_output() {
    local libc_info="$1"
    local c_library

    ## Extract the first line from the output
    local libc_output="$(echo "$libc_info" | $HEAD -n 1)"

    ## Find the C library - find a string enclosed in parathesis
    {
        c_library="$(echo $libc_output | $GREP -o '(.*)')"
    } && {
        remove_parantheses "$c_library"
        C_LIBRARY="$STRING_WITHOUT_PARATHESIS"
    } || {
        ## Do not log the error here. The error will be caught in the parent
        ## function by testing for an empty C_LIBRARY.
        return
    }

    ## Extract the C library version - find a string of word characters and
    ## period, after the string 'version '.
    local pattern_to_remove="version "
    {
        C_LIBRARY_VERSION="$(echo $libc_output | $GREP -o "version [0-9\.]*")"
    } || {
        ## Do not log the error here. The error will be caught in the parent
        ## function by testing for an empty C_LIBRARY_VERSION.
        return
    }

    C_LIBRARY_VERSION="${C_LIBRARY_VERSION#$pattern_to_remove}"
}

################################################################################
## Finds and executes the C library shared object file (libc.so.6). If libc.so.6
## is not found in the standard paths, the device could be using an old version
## of C library - libc.so.5 or older.
##
## ubuntu@dev-box:~$ find /lib* -name libc.so.6
## /lib/x86_64-linux-gnu/libc.so.6
##
## ubuntu@dev-box~$ /lib/x86_64-linux-gnu/libc.so.6
## GNU C Library (Ubuntu GLIBC 2.23-0ubuntu9) stable release version 2.23, by Roland McGrath et al.
## Copyright (C) 2016 Free Software Foundation, Inc.
## ...
## ...
################################################################################
get_libc_info_from_executable() {
    local message
    local libc_info

    ## Find the paths under /lib* where libc.so.6 could be present
    local libc_path="$($FIND /lib* -name 'libc.so.6' 2>/dev/null | $HEAD -n 1)"

    ## Execute libc.so.6
    {
        $TEST -n "$libc_path"
    } && {
        libc_info="$($libc_path)"
    } || {
        message="Failed to find the version of C library running on the device."
        message="$message\nYou could be using a very old version of C library."
        error "$message"
        add_to_errors "$message"
        return
    }

    ## Parse the output of libc.so.6
    parse_libc_output "$libc_info"
}

################################################################################
## Checks if the version of C library on the device meets the Greengrass core
## requirements.
################################################################################
check_libc_version() {
    local message
    local libc_version="$1"

    sanitize_version_string "$libc_version"
    libc_version="$SANITIZED_VERSION_STRING"

    compare_versions "$libc_version" "$MINIMUM_REQUIRED_LIBC_VERSION"
    if [ $GREATER_OR_EQUALS -ne 1 ]
    then
        wrap_bad "C library version" "$libc_version"
        message="Greengrass requires C library version"
        message="$message $MINIMUM_REQUIRED_LIBC_VERSION or greater to run"
        add_to_dependency_failures "$message"
        return
    fi

    wrap_info "C library version" "$libc_version"
}

################################################################################
## Checks the version of the C library used on the device.
################################################################################
get_libc_info() {
    local libc_info
    local os_info_output
    os_info_output=$(eval "cat /etc/*-release")

    if [ -z "${os_info_output##*"OpenWrt"*}" ]
    then
        echo "Glibc is not a requirement for Openwrt. Skipping glibc check."
    else

        { ## Try getting the C library info from 'ldd --version'
            libc_info="$(ldd --version 2>/dev/null)" && parse_ldd_output "$libc_info"
        } || { ## Fallback - run the executable 'libc.so.6' to get the C library info
            get_libc_info_from_executable
        } || {
            error "Could not find the version of C library running on the device"
            add_to_errors "Could not find the version of C library running on the device"
            return
        }

        if [ "$C_LIBRARY" = "" -o "$C_LIBRARY_VERSION" = "" ]
        then
            error "Failed to find information about the C library running on the device"
            add_to_errors "Failed to find information about the C library running on the device"
        else
            wrap_info "C library" "$C_LIBRARY"
            check_libc_version "$C_LIBRARY_VERSION"
        fi
    fi
}

################################################################################
## Greengrass core requires the '/var/run' directory to be present on the device.
## If not present, Greengrass core will fail to start.
################################################################################
check_var_run_present() {
    local message

    if [ -d "/var/run" ]
    then
        wrap_good "Directory /var/run" "Present"
    else
        wrap_bad "Directory /var/run" "Not found"
        message="Greengrass core requires the directory '/var/run' to be present"
        message="$message on the device.\nGreengrass core will otherwise fail"
        message="$message to start."
        add_to_dependency_failures "$message"
    fi
}

################################################################################
## Greengrass lambdas will fail to spin up if the '/dev/std{in,out,err}' files
## are not present on the device.
################################################################################
check_if_dev_stdio_file_exists() {
    local message
    local file_path="$1"
    local symlink_target="$2"

    if [ ! -e "$file_path" ]
    then
        message="Failed to find the file '$file_path' on the device.\n"
        message="$message\nCreate the file using the command 'ln -s $symlink_target"
        message="$message $file_path'. The symlink\nis not persistent across reboot,"
        message="$message so the command will need to be added to the boot\nsequence"
        message="$message for the device."
        wrap_bad "$file_path" "Not found"
        add_to_dependency_failures "$message"
        return
    fi

    wrap_good "$file_path" "Found"
}

check_dev_std_files_exist() {
    check_if_dev_stdio_file_exists "/dev/stdin" "/proc/self/fd/0"
    check_if_dev_stdio_file_exists "/dev/stdout" "/proc/self/fd/1"
    check_if_dev_stdio_file_exists "/dev/stderr" "/proc/self/fd/2"
}

check_system_configs() {
    header "System configuration:"
    get_kernel_architecture
    get_init_process
    check_kernel_version
    get_libc_info
    check_var_run_present
    check_dev_std_files_exist
}
