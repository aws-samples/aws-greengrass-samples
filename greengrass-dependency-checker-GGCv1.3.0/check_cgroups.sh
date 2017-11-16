CGROUPS_FILE="/proc/cgroups"
MOUNTS_FILE="/proc/mounts"

CGROUPS_NOT_SUPPORTED=0
CGROUPS_NOT_ENABLED=0

################################################################################
## Checks if the kernel supports cgroups.
################################################################################
check_kernel_supports_cgroups() {
    if [ ! -f "$CGROUPS_FILE" ]; then
        CGROUPS_NOT_SUPPORTED=1
    fi
}

################################################################################
## Checks if the 'devices' cgroup is enabled.
################################################################################
check_devices_cgroup_enabled() {
    local enabled_cgroups="$1"

    {
        echo "$enabled_cgroups" | $GREP 'devices' 2>/dev/null 1>&2
    } || {
        wrap_bad "Devices cgroup" "Not enabled"
        CGROUPS_NOT_ENABLED=1
    }
}

################################################################################
## Checks if the 'memory' cgroup is enabled.
################################################################################
check_memory_cgroup_enabled() {
    local enabled_cgroups="$1"

    {
        echo "$enabled_cgroups" | $GREP 'memory' 2>/dev/null 1>&2
    } || {
        wrap_bad "Memory cgroup" "Not enabled"
        CGROUPS_NOT_ENABLED=1
    }
}

################################################################################
## Verifies that the 'devcies' and 'memory' cgroups are compiled into the kernel.
##
## This check is redundant, since we already check if cgroups-related kernel
## configs are enabled - specifically, CONFIG_CGROUP_DEVICE and CONFIG_MEMCG.
################################################################################
check_cgroups_enabled() {
    local enabled_cgroups

    {
        enabled_cgroups=$($AWK '!/^#/ { if ($4 == 1) print $1 }' $CGROUPS_FILE)
    } && {
        check_devices_cgroup_enabled "$enabled_cgroups"
    } && {
        check_memory_cgroup_enabled "$enabled_cgroups"
    } || {
        error "Failed to check if all required cgroups are enabled"
        add_to_fatals "Failed to check if all required cgroups are enabled"
        return
    }
}

################################################################################
## Checks if the required cgroups are mounted.
################################################################################
check_cgroups_mounted() {
    local message
    local cgroups_dir
    local cgroups_mount_dir
    local devices_cgroup
    local memory_cgroup

    info "------------------------------------Cgroups check-----------------------------------"

    ## Check if the kernel supports cgroups.
    check_kernel_supports_cgroups

    ## Do not proceed, if the kernel does not support cgroups.
    if [ $CGROUPS_NOT_SUPPORTED -eq 1 ]
    then
        message="The kernel in use does NOT support cgroups. You will not be"
        message="$message able to run Greengrass\ncore without cgroups."
        fatal "$message"
        add_to_fatals "$message"
        info ""
        return
    fi

    ## Check if the required cgroups are enabled.
    check_cgroups_enabled

    ## Do not proceed if all of the required cgroups are not enabled.
    if [ $CGROUPS_NOT_ENABLED -eq 1 ]
    then
        error "One or more of the required cgroups is not enabled\n"
        add_to_fatals "One or more of the required cgroups is not enabled"
        info ""
        return
    fi

    ## Sample output for 'cat /proc/mounts':
    ## alinux % cat /proc/mounts
    ## proc /proc proc rw,relatime 0 0
    ## sysfs /sys sysfs rw,relatime 0 0
    ## devtmpfs /dev devtmpfs rw,relatime,size=3822864k,nr_inodes=955716,mode=755 0 0
    ## ..
    ## ..
    ## cgroup /sys/fs/cgroup tmpfs rw,relatime,mode=755 0 0
    ## cgroup /sys/fs/cgroup/cpuset cgroup rw,relatime,cpuset 0 0
    ## cgroup /sys/fs/cgroup/cpu cgroup rw,relatime,cpu 0 0
    ## cgroup /sys/fs/cgroup/cpuacct cgroup rw,relatime,cpuacct 0 0
    ## ..
    ##
    ##
    ## The below command filters the non-comment lines from the output, where the
    ## third column (filesystem type) is 'cgroup', prints the second column
    ## (cgroup mount path) of each such line and prints only the first of those
    ## lines. For the above sample, the output is '/sys/fs/cgroup/cpuset',
    ## so the 'cgroups_dir' variable would be set to '/sys/fs/cgroup/cpuset'.
    ##
    ##
    ## On most systems, the cgroup directory structure is as follows:
    ## alinux~$ cd /sys/fs/cgroup
    ## alinux:/sys/fs/cgroup$ ls
    ## blkio  cpu  cpuacct  cpuset  devices  freezer  hugetlb  memory  net_cls  perf_event
    ##
    ## On a few systems, like OpenWRT, individual directories do not exist for
    ## the cgroups:
    ## root@OpenWrt3:~# cd /sys/fs/cgroup
    ## root@OpenWrt3:~#/sys/fs/cgroup# ls
    ## cgroup.clone_children            devices.deny
    ## cgroup.event_control             devices.list
    ## cgroup.procs                     memory.failcnt
    ## cgroup.sane_behavior             memory.force_empty
    ## devices.allow                    memory.limit_in_bytes
    ##
    ## On such systems, the 'cgroups_dir' variable would be set to '/sys/fs/cgroup'.
    ##
    ## Output for 'cat /proc/mounts' on OpenWRT:
    ## root@OpenWrt3~# cat /proc/mounts
    ## ..
    ## devtmpfs /dev devtmpfs rw,relatime,size=3051452k,nr_inodes=762863,mode=755 0 0
    ## ..
    ## cgroup /sys/fs/cgroup cgroup rw,nosuid,nodev,noexec,relatime,memory,devices,freezer,pids 0 0
    ## ..
    cgroups_dir="$($AWK '!/^#/ { if ($3 == "cgroup") print $2 }' $MOUNTS_FILE | $HEAD -n 1)"

    ## Checking if cgroups_dir variable is set - i.e, if cgroups are mounted.
    if [ -z "$cgroups_dir" ]
    then
        message="It looks like cgroups are not mounted on the device."
        message="$message Refer to the official Greengrass\ndocumentation"
        message="$message to fix this."
        fatal "$message"
        add_to_fatals "$message"
        info ""
        return
    fi

    ## Get the cgroups mount directory - '/sys/fs/cgroup'
    cgroups_mount_dir="$($DIRNAME "$cgroups_dir")"
    if [ -d "$cgroups_mount_dir/cgroup" ]
    then
        cgroups_mount_dir="$cgroups_mount_dir/cgroup"
    fi
    info "Cgroups mount directory: $cgroups_mount_dir"
    info ""

    ## Check if the 'devices' cgroup is mounted
    devices_cgroup="$($LS "$cgroups_mount_dir" | $GREP "devices" | $WC -l)"
    if [ $devices_cgroup -eq 0 ]
    then
        message="The 'devices' cgroup is not mounted on the device. Greengrass"
        message="$message lambdas with Local\nResource Access(LRA) configurations"
        message="$message will not be allowed to open device files."
        wrap_warn "Devices cgroup" "Not mounted"
        add_to_warnings "$message"
    else
        wrap_good "Devices cgroup" "Mounted"
    fi

    ## Check if the 'memory' cgroup is mounted
    memory_cgroup="$($LS "$cgroups_mount_dir" | $GREP "memory" | $WC -l)"
    if [ $memory_cgroup -eq 0 ]
    then
        message="The 'memory' cgroup is not mounted on the device."
        message="$message Greengrass will fail to set\nthe memory limit of user"
        message="$message lambdas."
        wrap_bad "Memory cgroup" "Not mounted"
        add_to_fatals "$message"
    else
        wrap_good "Memory cgroup" "Mounted"
    fi

    info ""
}

