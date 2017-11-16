The script 'check_ggc_dependencies' verifies if the host device has all the
dependencies required to run Greengrass core v1.3.

Note:
1. Before you run the script, check on the AWS IoT console that a Greengrass
core binary is available for the kernel architecture on the device. You can
check the kernel architecture using the command 'uname -m':

alinux % uname -m
x86_64

2. The script does not install the missing dependencies for Greengrass core and
the Over The Air(OTA) agent. It only checks if the host device has all the
dependencies and generates a report of the missing dependencies.

================================================================================
Usage:
sudo ./check_ggc_dependencies
     [ --log-level  <LOG_LEVEL> | -log-level <LOG_LEVEL> ]
     [ -h | --help | -help ]
     [ -v | --version | -version ]
     [ --kernel-config-file  <KERNEL_CONFIG_PATH> | -kernel-config-file  <KERNEL_CONFIG_PATH> ]

LOG_LEVEL must be one of: 
          DEBUG, WARN (default), INFO, ERROR and FATAL

--version prints the version of Greengrass for which this script checks dependencies

KERNEL_CONFIG_PATH is the absolute/relative path of the kernel config file

Note that options can be specified with -- or -
Eg: --version or -version, --log-level or -log-level

================================================================================
Assumptions:

1. The device has the following commands:
   * echo
   * exit
   * set

2. The device has Linux installed.

3. The device has at least a 1GHz CPU and 128MB of RAM (more, depending
on the use case).

3. The device users are stored in /etc/passwd and groups in /etc/group.

4. The kernel config file is at /boot/config-`uname-r` or /proc/config.gz.
If neither of the two exists, the script suggests to run 'sudo modprobe configs'
to generate /proc/config.gz. Alternatively, the user can provide the kernel config
file as a command-line parameter using the --kernel-config-file option. If the
user-provided kernel config file is invalid, the script falls back to
/boot/config-`uname-r` and /proc/config.gz, in sequence.

5. The cgroups configuration is stored in /proc/cgroups.

6. /proc/mounts stores the definitive list of mounted filesystems.

7. The cgroups are all mounted at the same location, i.e, if the 'devices' cgroup
is mounted at /sys/fs/cgroup, then, the 'memory' cgroup should not be mounted at
a location other than /sys/fs/cgroup.

8. The shared libraries are in /usr/lib*, /lib* or /usr/local/lib and these
paths are added to the PATH environment variable.

9. /proc/1/exe is a symlink to the path of the init process.

================================================================================
Script dependencies (verfied by check_ggc_dependencies at startup):

The script requires the shell or Busybox variants of the following commands to
be present on the device:
1. printf
2. uname
3. cat
4. ls
5. head
6. find
7. zcat
8. awk
9. sed
10. sysctl
11. wc
12. cut
13. sort
14. expr
15. grep
16. test
17. dirname
18. readlink
19. xargs
20. strings
21. uniq
22. id

The following commands are not supported by Busybox but are required to be
present on the device:
1. eval
2. command
3. read

================================================================================
Greengrass core v1.3 dependencies:

1. Kernel version should be 4.4 or greater with OverlayFS enabled. The script
will warn if the kernel version is older than 4.4.

2. The version of C library (libc) on the device must be 2.14 or greater.

3. /var/run must be present on the device. Greengrass core will not start
otherwise.

4. The following files must be present on the device:
   a. /dev/stdin
   b. /dev/stdout
   c. /dev/stderr

5. Kernel configs:
    * Kernel configs for namespace:
      a. CONFIG_IPC_NS
      b. CONFIG_UTS_NS
      c. CONFIG_USER_NS
      d. CONFIG_PID_NS

    * Kernel configs for cgroups:
      a. CONFIG_CGROUP_DEVICE
      b. CONFIG_CGROUPS
      c. CONFIG_MEMCG

    * Other required kernel configs:
      a. CONFIG_POSIX_MQUEUE     
      b. CONFIG_OVERLAY_FS
      c. CONFIG_HAVE_ARCH_SECCOMP_FILTER
      d. CONFIG_SECCOMP_FILTER
      e. CONFIG_KEYS
      f. CONFIG_SECCOMP

6. Software packages:
   a. SQLite 3 or greater
      Greengrass requires SQLite for device shadows. The binary must be named
      'sqlite3' and be added to the PATH environment variable.
   b. Python 2.7
      Required if Python lambdas are used. The binary must be named 'python2.7'
      and the parent directory must be added to the PATH environment variable.
   c. NodeJS 6.10 or greater
      Required if NodeJS lambdas are used. The binary must be named 'nodejs6.10'
      and the parent directory must be added to the PATH environment variable.
   d. Java 8 or greater
      Required if Java lambdas are used. The binary must be named 'java8' and
      the parent directory must be added to the PATH environment variable.
   e. OpenSSL version 1.0.1 or greater
      The OTA(Over The Air) agent requires OpenSSL v1.0.1 or greater.
   f. wget
      The OTA(Over The Air) agent requires the 'wget' command to be present on
      the device.
   g. realpath
      The OTA(Over The Air) agent requires the 'realpath' command to be present
      on the device.
   h. tar
      The OTA(Over The Air) agent requires the 'tar' command to be present
      on the device.

7. Cgroups:
   a. The kernel must support cgroups.
   b. The 'devices' cgroup must be enabled and mounted if lambdas with Local
      Resource Access(LRA) configurations are used to open device files.
   c. The 'memory' cgroup must be enabled and mounted to allow Greengrass to
      set the memory limit for user lambdas.

8. Hardlinks and symlinks protection:
   Required to run Greengrass in the secure mode. Without this configuration,
   Greengrass core can be run only in the insecure mode using the -i flag.

9. User 'ggc_group', group 'ggc_group':
   Greengrass core will not start without ggc_user and ggc_group.

================================================================================
