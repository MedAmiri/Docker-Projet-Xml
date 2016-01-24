Hi all

Got the same issue here on a dedicated OVH Slackware server using default OVH kernel (Linux 3.10.23-xxxx-std-ipv6-64).

You should first ensure that your cgroups hierarchy is correctly mounted (see below).
You should also ensure that lxc-checkconfig returns enabled for all feature. Some made-in-OVH kernels (< 3.11) don't have CONFIG_PID_NS=y for instance. If this is the case for your kernel, check how to configure and rebuild your made-in-OVH kernel below OR simply upgrade with OVH netboot your OVH kernel version to another OVH kernel having the correct configuration (3.14.X looks good, confs are here ftp://ftp.ovh.net/made-in-ovh/bzImage/) .
For people that want AUFS support with Docker on made-in-OVH kernels or who can't choose a newer kernel version with OVH netboot you can follow the how to below to reconfigure your existing made-in-OVH kernel for Docker support.

Docker (+ AUFS support) for made-in-OVH kernels

Generic Linux commands given so that you can apply them on your favorite Linux flavor.

Tested on Slackware X86_64 - Linux 3.10.23-xxxx-std-ipv6-64

Choose a kernel version you want to use either based on your current OVH kernel or from one available here: ftp://ftp.ovh.net/made-in-ovh/bzImage/
=> Up to you.

Prepare a build folder to keep things clean:
$ mkdir /home/build
$ mkdir /home/build/kheaders/
$ cd /home/build
Get the kernel sources and the custom OVH config for your chosen kernel (3.14.18 here)
$ wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.18.tar.xz
$ tar xf linux-3.14.18.tar.xz
$ cd linux-3.14.18
$ make mrproper
$ wget ftp://ftp.ovh.net/made-in-ovh/bzImage/3.14.18/config-3.14.18-xxxx-std-ipv6-64
$ mv config-3.14.18-xxxx-std-ipv6-64 .config
$ make oldconfig
[AUFS support only] Get AUFS source tree:
Ref: http://docker.readthedocs.org/en/v0.5.3/installation/kernel/

Notes: I'm using AUFS standalone source tree as OVH kernels have no loadable module support by default and we want here to keep the OVH kernel default configuration as untouched as possible.

$ cd /home/build
$ git clone git://git.code.sf.net/p/aufs/aufs3-standalone aufs-aufs3-standalone
$ cd aufs-aufs3-standalone
[AUFS support only] Patch the kernel sources with the correct AUFS version you need
Ref 1: http://aufs.sourceforge.net/
Ref 2: http://sourceforge.net/p/aufs/aufs3-standalone/ci/master/tree/

Notes: Choose your AUFS version based on your kernel version as described in Ref 1.
In my case, Kernel 3.6.14 => aufs3.14

$ git branch -a
$ git checkout origin/aufs3.14
$ cd  /home/build/linux-3.14.18
$ patch -p1 < ../aufs-aufs3-standalone/aufs3-kbuild.patch
$ patch -p1 < ../aufs-aufs3-standalone/aufs3-base.patch
$ patch -p1 < ../aufs-aufs3-standalone/aufs3-mmap.patch
$ cp -r ../aufs-aufs3-standalone/{Documentation,fs} .
$ cp ../aufs-aufs3-standalone/include/uapi/linux/aufs_type.h include/uapi/linux/
[AUFS support only] Add AUFS support in your kernel configuration:
$ make menuconfig
File systems > Miscellaneous filesystems > Aufs (Advanced multi layered unification filesystem) support

Required Docker Kernel configuration:
Ensure the following configuration is at least set (it is the case for config-3.14.18-xxxx-std-ipv6-64 as well as others made-in-OVH kernels >= 3.14):

$ make menuconfig
General setup --->
    [*] Control Group support --->
        [ ] Example debug cgroup subsystem
        [*] Freezer cgroup subsystem
        [*] Device controller for cgroups
        [*] Cpuset support
        [*]  Include legacy /proc/<pid>/cpuset file
        [*] Simple CPU accounting cgroup subsystem
        [*] Resource counters
        [*]  Memory Resource Controller for Control Groups
        [*]   Memory Resource Controller Swap Extension
        [*]    Memory Resource Controller Swap Extension enabled[...]
        [*]   Memory Resource Controller Kernel Memory accountin[...]
        [*] Enable perf_event per-cpu per-container group (cgrou[...]
        [*] Group CPU scheduler --->
            [*] Group scheduling for SCHED_OTHER (NEW)
            [*]  CPU bandwidth provisioning for FAIR_GROUP_SCHED
            [ ] Group scheduling for SCHED_RR/FIFO
        [*] Block IO controller
        [ ]  Enable Block IO controller debugging
    -*-  Namespaces support --->
        [*] UTS namespace
        [*] IPC namespace
        [*] User namespace
        [*] PID Namespaces
        [*] Network namespace
Compile and install the changed kernel:
$ make -j 2
# make install
=> Ensure that your lilo/grub configuration and /boot* files are correct.
=> Ensure that your server will boot on its hard drive in your OVH manager (no netboot).

Do not reboot yet!

[AUFS support only] Export the kernel headers for aufs-utils compilation:
We are mostly interested here in the userspace version of /include/linux/aufs_type.h we added before to our Linux source tree that will be produced here.

# make headers_install INSTALL_HDR_PATH=/home/build/kheaders/
[AUFS support only] Get aufs-utils source tree
$ cd  /home/build/
$ git clone git://git.code.sf.net/p/aufs/aufs-util aufs-aufs-util
$ cd aufs-aufs-util
$ git branch -a
Notes: "You may not be able to find the GIT branch in aufs-util for your
version. In this case, you should git-checkout the branch for the
nearest lower number."

aufs-utils 3.9 is the version to use with aufs3.14

Ref: http://sourceforge.net/p/aufs/aufs-util/ci/aufs3.9/tree/README

[AUFS support only] Compile aufs-utils
Note: We pass extra flags to indicate where is the required aufs headers exported before.

Ref: http://sourceforge.net/p/aufs/aufs-util/ci/aufs3.9/tree/README

$ git checkout origin/aufs3.9
$ make CPPFLAGS="-I /home/build/kheaders/include -I /home/build/aufs-aufs3-standalone/include"
# make install
Reboot
# reboot
Given that the minimal configuration changes added to the reference OVH configuration, it should be a smooth reboot, especially if you are are not upgrading your kernel version.

Kernel configuration checking
You can use lxc-checkconfig to ensure proper kernel configuration

Default 3.10.23-xxxx-std-ipv6-64 OVH kernel returns:

# lxc-checkconfig
--- Namespaces ---
Namespaces: enabled
Utsname namespace: enabled
Ipc namespace: enabled
Pid namespace: required
User namespace: missing
Network namespace: enabled
Multiple /dev/pts instances: missing
...
This OVH Kernel 3.14.18-xxxx-std-ipv6-64 returns:

# lxc-checkconfig
--- Namespaces ---
Namespaces: enabled
Utsname namespace: enabled
Ipc namespace: enabled
Pid namespace: enabled
User namespace: enabled
Network namespace: enabled
Multiple /dev/pts instances: enabled
...
Create cgroups hierarchy
Either by using /etc/fstab:

# echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> /etc/fstab
# mkdir -p /sys/fs/cgroup
# mount /sys/fs/cgroup
or using https://github.com/tianon/cgroupfs-mount

Run docker to see the issue described in this thread is fixed
# docker run ubuntu echo "hello world"
hello world
