                    FuguIta - The OpenBSD-based Live System

                                                             Yoshihiro Kawamata
                                                                     2025/04/19


Table of Contents

* What is FuguIta?
 ** Features
  *** Easy to use
  *** Tracking patches of OpenBSD
  *** Flexible Operation
  *** Utilize LiveUSB features
  *** Support tools provided
  *** Remastering and Customization
 ** More Informations
* Build FuguIta from the source repository
 ** Getting started
  *** About notation
 ** Preparing the build environment
  *** Setting environment variables
  *** OpenBSD full build
  *** Installing the commands for build
  *** Get the source code of FuguIta
  *** Get the source code archives for fiopt
 ** Generate a LiveDVD ISO image file
  *** Initialize the FuguIta build tool
  *** Build fiopt
  *** Placement of necessary files
  *** Generate the ISO file
 ** Creating the LiveUSB disk image file
 ** Adjustment
 ** Final Processing
  *** Generate a blank LiveUSB image
  *** Cleaning up the build environment
 ** Batch generation of LiveDVDs and LiveUSBs

*What is FuguIta?

FuguIta is a live system based on OpenBSD operating system.

The primary goal of this project is to make OpenBSD, a superior operating
system, easily accessible to everyone.

In addition, we have implemented a variety of unique features that take
advantage of the characteristics of a live system.

**Features

***Easy to use

  - Bootable from DVD or USB memory stick, no need to install to PC's internal
    storage.

  - Operates almost like a normally installed OpenBSD, and the built-in online
    manual can be used as it is.

  - Additional software can be installed using OpenBSD's package management
    system.

***Tracking patches of OpenBSD

  - We publish new release of FuguIta as soon as the OpenBSD development group
    announces new errata (security fixes and reliability enhancements).

  - FuguIta itself is also modified and added functions as needed.

***Flexible Operation

  - Three boot modes can be selected according to the performance of the
    hardware.

      + Mode 0: FuguIta's standard boot mode

      + Mode 1: Short boot time and memory-saving operation

      + Mode 2: Transfers the entire system to memory for faster operation

      + Mode 3: Boot by loading a previously saved files or directories

      + etc ...

  - Multiple FuguIta devices can be attached to accommodate irregular hardware
    configurations.

***Utilize LiveUSB features

  - Save files and load them at the subsequence boot (can be automated).

  - Update tool for easy and safe updating.

***Support tools provided

  - Interactive tools are included for network setup and desktop
    environment setup.

***Remastering and Customization

  - Remastering LiveDVD and LiveUSB on running FuguIta.

      + LiveDVD to LiveUSB and LiveUSB to LiveDVD remastering are also
        possible.

  - Customization is also possible by modifying the contents during the
    duplication process.

  - LiveUSB duplication can also encrypt the partition for data storage.

**More Information

The official site of FuguIta is https://fuguita.org .

  - Getting Started with FuguIta - A guide to setting up and
    fundamental usage of FuguIta.
    https://fuguita.org/?FuguIta/StartGuide

  - FuguIta Guide
    A comprehensive document of FuguIta - setting up, fundamental and
    advanced usage, development.
    https://fuguita.org/?FuguItaGuide

*Build FuguIta from the source repository

**Getting Started

The build system for the OpenBSD-based Live System "FuguIta" is
available on GitHub as a copy from the original CVS repository.

This document explains how to obtain the FuguIta build tool from the
GitHub repository and use it to build FuguIta.

The steps to build FuguIta are roughly as follows:

 1. Prepare the working environment, including a full build of OpenBSD

 2. Generate ISO image file for FuguIta LiveDVD

 3. Boot the created ISO image file and create a LiveUSB disk image
    file on it.

 4. Create a blank file for creating a LiveUSB from the created
    LiveUSB disk image file.

 5. After making the final adjustments, generate the final version of
    the LiveDVD ISO image file and LiveUSB disk image file.

***About Notation

In this document, the following notation is used:

<BASEDIR>
    Location of working directory (e.g. /home/kaw/local)
<WORKDIR>
    Directory where the build work will be performed (directory of the
    build tool obtained from GitHub = <BASEDIR>/FuguIta-master)
<RELDIR>
    Location of the OpenBSD installation set
    (e.g. /opt/build/dist/amd64)
<REL>
    OpenBSD release (e.g. 7.6)
<SREL>
    REL without the dot (e.g. 76)
<ARCH>
    The target platform (e.g. amd64)

When running a build, replace these notations with the actual values.

**Preparing the build environment

From now on, everything from preparing the build environment to
completing the build process will be done with root privileges.

***Setting environment variables

Set the following environment variables as necessary.  These
environment variables are optional, so the build system will work even
if you do not set them. If you set them, you can take advantage of the
performance of multi-core CPUs to reduce processing time.

  export KERNOPT=-j4    # Number of parallel executions when building the kernel
  export COMPRESS=pigz  # Multi-core compatible gzip alternative

***OpenBSD full build

To build FuguIta, you need the OpenBSD source code, an installation
set created from the source code, and a ports tree. Follow the
instructions in the OpenBSD release(8) manual page
https://man.openbsd.org/release.8
to do the following:

  - Obtaining and updating the OpenBSD source code
  - OpenBSD full build
  - Generate an installation set
  - Obtaining and updating the ports tree

***Installing commands for build

Install third-party commands required to build FuguIta from packages
to the build environment.

  pkg_add gmake rsync pv
  pkg_add pigz  # (If you set the COMPRESS environment variable)

***Get the source code for FuguIta

Get the FuguIta build system from GitHub

mkdir -p <BASEDIR> # If <BASEDIR> does not exist, create it.

  cd <BASEDIR>
  ftp https://github.com/ykaw/FuguIta/archive/refs/heads/master.tar.gz
  tar xvzf master.tar.gz  # The FuguIta-master directory will be created.
  cd <WORKDIR>

***Get the source code archives for fiopt

fiopt (FuguIta Optional) is third-party software required to run
FuguIta.
In the current release, there are three: rsync, rlwrap, and pv. These
are built separately from ports and installed under /usr/fuguita/bin.
Obtain the source code for these using the OpenBSD ports system as
follows. The source code is placed in /usr/ports/distfiles.

  cd /usr/ports
  for tgz in rsync xxhash rlwrap pv; do (cd */$tgz && make fetch); done

xxhash is a fast hashing library used when building rsync.

***Creating a LiveDVD ISO image file

Initialize the FuguIta build tool

Create the directories required for the build.

  cd <WORKDIR>
  make init

***Build fiopt

Compile and install each piece of fiopt software. The installed
software will be compiled into an archive named fiopt.tgz.

  cd <WORKDIR>/lib/fiopt
  ln -s /usr/ports/distfiles/*.tar.gz .
  make RSYNC=rsync-3.4.1 XXHASH=xxHash-0.8.2 RLWRAP=rlwrap-0.46.1 PV=pv-1.8.5

The version of each software should match what was actually acquired.

***Placement of necessary files

Place OpenBSD release sets and third-party software in the
install_sets directory.

  cd <WORKDIR>/install_sets
  ln -s <RELDIR>/*<SREL>.tgz .
  ln -s <WORKDIR>/lib/fiopt/fiopt<SREL>.tgz .

In this example, a symbolic link is used, but copying is also possible.

***Generate the ISO file

Generate the LiveDVD release file

  cd <WORKDIR>
  make setup    # Set up the bootloader, RAMdisk root, and fuguita-<REL>-<ARCH>.ffsimg
  make livedvd  # Set up the OS file tree and write it to an image file


**Creating the LiveUSB disk image file

This build system does not have the ability to create a LiveUSB
release image from scratch, so boot the LiveDVD ISO image you just
generated.

  - On the launched FuguIta, use the newdrive function of the usbfadm
    utility to create a LiveUSB release image .
  - Create a fast boot cache

      cd /etc/fuguita
      gen_mode0sldir
      ls -l  # Verify that the mode0symlinks.cpio.gz file has been created

Copy the LiveUSB image and fast boot cache you created to the original
build environment.

  mount /dev/sdXn /mnt
  cp FuguIta-<REL>-<ARCH>-yyyymmddn.img /mnt/<WORKDIR>
  cp /etc/fuguita/mode0symlinks.cpio.gz /mnt/<WORKDIR>/lib/mode0symlinks.cpio.gz.<ARCH>
  umount /mnt

Stop the environment in which the LiveUSB release image was created
and return to the original build environment.

**Adjustment

The file <WORKDIR>/lib/global.conf.<ARCH> defines the system constants
for FuguIta, but you should rewrite these to the optimal values
​​obtained by actually building the package.

  expr $(wc -c < livecd.iso) / 1024 / 1024 + 10
  1149  # Size of LiveUSB a partition
  vi lib/global.conf.<ARCH>

  fuguita_sys_mb=1149   # size of sysmedia.img <-- Set the value calculated earlier here
  newdrive_defswap=16M  # default swap size at usbfadm newdrive
  memfstype=mfs         # 'mfs' or 'tmpfs'
  mfs_max_mb=30720      # mfs hard limit - 30GB

**Final Processing

***Generate a blank LiveUSB image

A LiveUSB blank image is a raw LiveUSB disk image that has been erased
with everything except the partition configuration, boot loader, and
livecd-config/<REL>/<ARCH>/noasks in the d partition.
Using a blank LiveUSB image allows you to generate a LiveUSB image
directly from the build system, without having to boot a LiveCD and
then use usbfadm newdrive to create a LiveUSB image.

Follow the steps below to create a blank LiveUSB image:

  make blank-img
  make blank-img-clean

After this step, a file called sysmedia-<REL>-<ARCH>.img.gz will be
generated, which is the compressed blank LiveUSB image.

***Cleaning up the build environment

The following steps will initialize the build system, leaving only the
blank LiveUSB image.

  rm -rf sysmedia/*
  rm -f FuguIta-<REL>-<ARCH>-*.iso FuguIta-<REL>-<ARCH>-*.img
  make distclean

**Batch creation of LiveDVDs and LiveUSBs

Generate the official distribution from the initialized build system.
Execute "make all" to generate the FuguIta LiveDVD ISO image and
LiveUSB disk image in one go.

  make init
  cd <WORKDIR>/install_sets
  ln -s <WORKDIR>/lib/fiopt/fiopt<SREL>.tgz .
  ln -s <RELDIR>/*<SREL>.tgz .
  cd <WORKDIR>
  make setup && make all

Finally, FuguIta-<REL>-<ARCH>-yymmddn.iso.gz and
FuguIta-<REL>-<ARCH>-yymmddn.iso.gz will be generated.
