CGROUPS_FILE="/proc/cgroups"
MOUNTS_FILE="/proc/mounts"

CGROUPS_NOT_SUPPORTED=0

################################################################################
## Checks if the kernel supports cgroups.
################################################################################
check_kernel_supports_cgroups() {
    if [ ! -f "$CGROUPS_FILE" ]
    then
        CGROUPS_NOT_SUPPORTED=1
    fi
}

################################################################################
## Checks if the 'devices' cgroup is enabled and mounted.
################################################################################
check_devices_cgroup_enabled_and_mounted() {
    local cgroups_mount_dir="$1"
    local message
    local devices_cgroup

    ## Enabled cgroups can be checked for from the output of 'cat /proc/cgroups':
    ## alinux % cat /proc/cgroups
    ## #subsys_name    hierarchy   num_cgroups enabled
    ## cpuset  1   1   1
    ## cpu     2   1   1
    ## cpuacct 3   1   1
    ## blkio   4   1   1
    ## memory  5   1   1
    ## devices 6   1   1
    ## freezer 7   1   1
    ## net_cls 8   1   1
    ## perf_event  9   1   1
    ## hugetlb 10  1   1
    ##
    ## A '1' in the fourth coulmn against a cgroup in the above output indicates
    ## that the cgroup is enabled.
    ##
    ## In the below command,
    ## !/^#/      => Filter non-comment lines.
    ## ($4 == 1)  => Filter lines where the fourth column is '1'
    ## print $1   => Print the first column (cgroup name) of each filtered line.
    enabled_cgroups=$($AWK '!/^#/ { if ($4 == 1) print $1 }' $CGROUPS_FILE)
    {
        echo "$enabled_cgroups" | $GREP 'devices' 2>/dev/null 1>&2
    } || {
        message="The 'devices' cgroup is not enabled on the device.\n"
        message="$message\nGreengrass lambdas with Local Resource Access(LRA)"
        message="$message configurations will not be allowed\nto open device files."
        wrap_warn "Devices cgroup" "Not enabled"
        add_to_dependency_warnings "$message"
        return
    }

    ## Check if the 'devices' cgroup is mounted.
    ##
    ## root@alinux:~# ls /sys/fs/cgroup
    ## cgroup.clone_children  cgroup.sane_behavior  devices.list
    ## cgroup.event_control   devices.allow         memory.failcnt
    ## cgroup.procs           devices.deny          memory.force_empty
    ## ..
    ## ..
    ##
    ## root@alinux:~# ls /sys/fs/cgroup | grep devices
    ## devices.allow
    ## devices.deny
    ## devices.list
    ##
    ## root@alinux:~# ls /sys/fs/cgroup | grep devices | wc -l
    ## 3
    devices_cgroup="$($LS "$cgroups_mount_dir" | $GREP "devices" | $WC -l)"
    if [ $devices_cgroup -eq 0 ]
    then
        message="The 'devices' cgroup is not mounted on the device.\n"
        message="$message\nGreengrass lambdas with Local Resource Access(LRA)"
        message="$message configurations will not be allowed\nto open device files."
        wrap_warn "Devices cgroup" "Not mounted"
        add_to_dependency_warnings "$message"
    else
        wrap_good "Devices cgroup" "Enabled and Mounted"
    fi
}

################################################################################
## Checks if the 'memory' cgroup is enabled and mounted.
################################################################################
check_memory_cgroup_enabled_and_mounted() {
    local cgroups_mount_dir="$1"
    local message
    local memory_cgroup

    enabled_cgroups=$($AWK '!/^#/ { if ($4 == 1) print $1 }' $CGROUPS_FILE)
    {
        echo "$enabled_cgroups" | $GREP 'memory' 2>/dev/null 1>&2
    } || {
        message="The 'memory' cgroup is not enabled on the device."
        message="$message\nGreengrass will fail to set the memory limit of user"
        message="$message lambdas."
        wrap_bad "Memory cgroup" "Not enabled"
        add_to_dependency_failures "$message"
        return
    }

    memory_cgroup="$($LS "$cgroups_mount_dir" | $GREP "memory" | $WC -l)"
    if [ $memory_cgroup -eq 0 ]
    then
        message="The 'memory' cgroup is not mounted on the device."
        message="$message\nGreengrass will fail to set the memory limit of user"
        message="$message lambdas."
        wrap_bad "Memory cgroup" "Not mounted"
        add_to_dependency_failures "$message"
    else
        wrap_good "Memory cgroup" "Enabled and Mounted"
    fi
}

################################################################################
## Verifies that the 'devcies' and 'memory' cgroups are enabled and mounted.
################################################################################
check_cgroups_enabled_and_mounted() {
    local cgroups_mount_dir="$1"

    check_devices_cgroup_enabled_and_mounted "$cgroups_mount_dir"
    check_memory_cgroup_enabled_and_mounted "$cgroups_mount_dir"
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
        add_to_dependency_failures "$message"
        info ""
        return
    fi

    ## Find the directory where cgroups are mounted on the device.
    ##
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
        message="It looks like the cgroups directory is not mounted on the device."
        message="$message\nRefer to the official Greengrass documentation"
        message="$message to fix this."
        fatal "$message"
        add_to_dependency_failures "$message"
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

    ## Check if the required cgroups are enabled and mounted.
    check_cgroups_enabled_and_mounted "$cgroups_mount_dir"

    info ""
}

