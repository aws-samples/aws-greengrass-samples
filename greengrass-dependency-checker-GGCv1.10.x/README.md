# Greengrass core v1.10.x dependencies checker

The script 'check\_ggc\_dependencies' verifies if the host device has all the
dependencies required to run Greengrass core v1.10.x.


**Note**
* Before you run the script, check on the AWS IoT console that a Greengrass
core binary is available for the kernel architecture on the device. You can
check the kernel architecture using the command 'uname \-m':

     ```
     alinux % uname -m
     x86_64
     ```

* The script does not install the missing dependencies for Greengrass core and
the Over The Air(OTA) agent. It only checks if the host device has all the
dependencies and generates a report of the missing dependencies.


### Usage
```
sudo ./check_ggc_dependencies [options]

--log-level | -log-level                    : DEBUG, WARN (default), INFO, ERROR or FATAL
-h | --help | -help                         : Prints the script usage
-v | --version | -version                   : Prints the version of Greengrass core for which the script checks dependencies
--kernel-config-file | -kernel-config-file  : The absolute/relative path of the kernel config file on the device

Options can be specified with -- or -
Eg: --version or -version, --log-level or -log-level
```

### Assumptions

* The device has Linux installed.

* The device has the following commands:
   * echo
   * exit
   * set

* The device has at least a 1GHz CPU and 128MB of RAM (more, depending
on the use case).

* The device users are stored in `/etc/passwd` and groups in `/etc/group`.

* The kernel config file is at ``/boot/config-`uname -r` `` or `/proc/config.gz`.
If neither of the two exists, the script suggests to run `sudo modprobe configs`
to generate `/proc/config.gz`. Alternatively, the user can provide the kernel config
file as a command-line parameter using the `--kernel-config-file` option. If the
user-provided kernel config file is invalid, the script falls back to
``/boot/config-`uname -r` `` and `/proc/config.gz`, in sequence.

* The cgroups configuration is stored in `/proc/cgroups`.

* `/proc/mounts` stores the definitive list of mounted filesystems.

* The cgroups are all mounted at the same location, i.e, if the 'devices' cgroup
is mounted at `/sys/fs/cgroup`, then, the 'memory' cgroup should not be mounted at
a location other than `/sys/fs/cgroup`.

* The shared libraries are in `/usr/lib*`, `/lib*` or `/usr/local/lib` and these
paths are added to the `PATH` environment variable.

* `/proc/1/exe` is a symlink to the path of the init process.

### Script dependencies (verfied by check_ggc_dependencies at startup)

The script requires shell or Busybox variants of the following commands to
be present on the device:
* printf
* uname
* cat
* ls
* head
* find
* zcat
* awk
* sed
* wc
* cut
* sort
* expr
* grep
* test
* dirname
* readlink
* xargs
* strings
* uniq
* id

The following shell commands are not supported by Busybox but are required to be
present on the device:
* eval
* command
* read

### Greengrass core v1.10.x dependencies

* Kernel version must be `3.17 or greater`. The script will print an error if the kernel
version is older than `3.17`.

* Kernel version is recommended to be `4.4 or greater` with OverlayFS enabled. The script
will warn if the kernel version is older than `4.4`.

* The version of C library (libc) on the device must be `2.14 or greater`.

* `/var/run` must be present on the device. Greengrass core will not start
otherwise.

* The following files must be present on the device:
  * `/dev/stdin`
  * `/dev/stdout`
  * `/dev/stderr`

* **Kernel configs**
  * Kernel configs for namespace:
    * CONFIG_IPC_NS
    * CONFIG_UTS_NS
    * CONFIG_USER_NS
    * CONFIG_PID_NS

  * Kernel configs for cgroups:
    * CONFIG_CGROUP_DEVICE
    * CONFIG_CGROUPS
    * CONFIG_MEMCG

  * Other required kernel configs:
    * CONFIG_POSIX_MQUEUE     
    * CONFIG_OVERLAY_FS
    * CONFIG_HAVE_ARCH_SECCOMP_FILTER
    * CONFIG_SECCOMP_FILTER
    * CONFIG_KEYS
    * CONFIG_SECCOMP
    * CONFIG_SHMEM

* **Software packages**
  * `Python 2.7 or Python 3.7`  
  Required if Python lambdas are used. The binaries must be named 'python2.7'
  and 'python3.7' respectively and the parent directory must be added to the 
  PATH environment variable.
  * `NodeJS 12.x or greater`
  Required if NodeJS lambdas are used. The binary must be named 'nodejs12.x'
  and the parent directory must be added to the PATH environment variable.
  (Existing Lambda functions that use Node.js 6.10 and Node 8.10 runtime can still run on
  Greengrass core, but they can’t be updated after 5/30/2019 and 2/3/2020 respectively. Please refer
  to [AWS Lambda Runtimes Support Policy](https://docs.aws.amazon.com/lambda/latest/dg/runtime-support-policy.html).)
  * `Java 8 or greater`  
  Required if Java lambdas are used. The binary must be named 'java8' and
  the parent directory must be added to the PATH environment variable.

* **Cgroups**
  * The kernel must support cgroups.
  * The 'devices' cgroup must be enabled and mounted if lambdas with Local
    Resource Access(LRA) configurations are used to open device files.
  * The 'memory' cgroup must be enabled and mounted to allow Greengrass to
    set the memory limit for user lambdas.

* **Hardlinks and symlinks protection**  
  Required to run Greengrass in the secure mode. Without this configuration,
  Greengrass core can be run only in the insecure mode using the -i flag.

* **User 'ggc_user', group 'ggc_group'**  
  Greengrass core will not start without ggc_user and ggc_group unless the
  corresponding UID and/or GID have been set in the deployed Greengrass
  Group's DefaultFunctionExecutionConfig. See the Greengrass documentation
  for further information.

* **Over The Air(OTA) agent requirements**
  * Shell commands: (not the BusyBox variants)
     * `wget`
     * `realpath`
     * `tar`
     * `readlink`
     * `basename`
     * `dirname`
     * `pidof`
     * `df`
     * `grep`
     * `umount`
     * `mv`
     * `gzip`
     * `mkdir`
     * `rm`
     * `ln`
     * `cut`
     * `cat`
