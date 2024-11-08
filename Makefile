# Copyright (c) 2005--2024, Yoshihiro Kawamata
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
# 
#   * Neither the name of the Yoshihiro Kawamata nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# $Id: Makefile,v 1.131 2024/11/08 02:56:28 kaw Exp $

#========================================
# global definitions
#
PROJNAME = FuguIta
VERSION != uname -r
VER     != uname -r | tr -d .
# e.g. VERSTAT=_cur
VERSTAT  =
ARCH    != uname -m
DATE    != date +%Y%m%d
REV     != if [[ -r rev.count ]] ; then\
               rev=$$(cat rev.count);\
           else\
               rev=1;\
           fi;\
           [[ $$rev -le 0 ]] && rev=1;\
           echo $$rev
AUTHOR = Yoshihiro Kawamata <kaw@on.rim.or.jp>
FIBASE = $(VERSION)$(VERSTAT)-$(ARCH)-$(DATE)$(REV)
FI = $(PROJNAME)-$(FIBASE)

BLDDIR != realpath $$(pwd)

KERNSRC = $(BLDDIR)/sys
KERNOPT = -j2
BSD_SP  = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/bsd
BSD_SPG = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/gapdummy.o
BSD_SPV = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/vers.o
BSD_MP  = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd
BSD_MPG = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/gapdummy.o
BSD_MPV = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/vers.o
KERN_SP = $(BLDDIR)/sysmedia/bsd-fi
KERN_MP = $(BLDDIR)/sysmedia/bsd-fi.mp

COMPRESS = gzip

# define and setup UEFI CD boot
# if UEFI applications exist
#
.if exists(/usr/mdec/BOOTIA32.EFI)
.    if exists(/usr/mdec/BOOTX64.EFI)
EFICD=1
EFICDBOOT_SIZE=350K
EFICD_OPT=-e eficdboot
MAKE_EFICD=$(MAKE) sysmedia/eficdboot
.    endif
.endif

# dummy command for non-UEFI boot
#
.ifndef MAKE_EFICD
MAKE_EFICD=true
.endif

# define CD boot for arm64
#
.if $(ARCH) == arm64
.  if exists(/usr/mdec/BOOTAA64.EFI)
ARM64_ISO=1
.  endif
.endif

#========================================
# final target
#
.PHONY: all livedvd liveusb
all:
	$(MAKE) livedvd
	$(MAKE) liveusb
# increase revision
	echo $$(($(REV)+1)) > rev.count
# to reorder kernel at next compilation
	$(MAKE) kernreset

livedvd: $(FI).iso.gz
liveusb: $(FI).img.gz

# build an ISO image
#
$(FI).iso.gz: livecd.iso
	@echo generating $(FI).iso.gz
	@pv livecd.iso | $(COMPRESS) -9f -c > $(FI).iso.gz

# build a disk image
# This needs sysmedia.img
#
.if exists(sysmedia.img)
$(FI).img.gz: sysmedia.time
	$(MAKE) open-sysmedia
	$(MAKE) sysmedia/boot sysmedia/cdboot sysmedia/cdbr sysmedia/etc/boot.conf\
                $(KERN_SP) $(KERN_MP)\
                sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg
	$(MAKE_EFICD)
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-all
	@echo generating $(FI).img.gz
	@pv sysmedia.img | $(COMPRESS) -9f -c > $(FI).img.gz
.else
$(FI).img.gz:
	@echo You need sysmedia.img to build $(FI).img.gz.
.endif

# sync staging to sysmedia/fuguita-*.ffsimg
#
.PHONY: sync
sync: staging.time
	$(MAKE) open-fuguita
#	 equalize fuguita directory to staging:
#	 When applying a patch and resynchronizing, media.img may overflow,
#	 so in that case, delete some large files and rerun rsync.
	cd staging &&\
	if ! rsync -avxH --delete . ../fuguita/.; then\
	    find ../fuguita/ -type f -size +4096 -print | xargs rm;\
	    rsync -avxH --delete . ../fuguita/.;\
	fi
	$(MAKE) close-fuguita

# fill into sysmedia (or sysmedia.img)
#
sysmedia.time:
	$(MAKE) open-fuguita
	$(MAKE) sysmedia/boot sysmedia/cdboot sysmedia/cdbr sysmedia/etc/boot.conf\
                $(KERN_SP) $(KERN_MP)\
                sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg
	$(MAKE_EFICD)
#	fuguita closed in above rules, then reopen it
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-fuguita
	touch sysmedia.time

# generate an ISO file
#
livecd.iso: sysmedia.time
	mkhybrid -a -R -L -l -d -D -N\
		-o livecd.iso\
		-v -v\
		-A "FuguIta: OpenBSD-based Live System"\
		-P "Copyright (c) `date +%Y` Yoshihiro Kawamata"\
		-p "Yoshihiro Kawamata, https://fuguita.org/"\
		-V "$(FI)"\
		-b cdbr\
		$(EFICD_OPT)\
		-c boot.catalog\
		sysmedia\

# on arm64, following boot loaders are not required
# but null (dummy) files must be exist for usbfadm newdrive
#
.for bootstuff in boot cdboot
.    if exists($(bootstuff))
sysmedia/$(bootstuff): /usr/mdec/$(bootstuff)
.    else
sysmedia/$(bootstuff):
.    endif
# To keep the i-node number the same
# so that the PBR does not lose sight of /boot
	-cat /usr/mdec/$(bootstuff) >sysmedia/$(bootstuff)
.endfor

# if an UEFI application for arm64 exists, create a cdbr
#
sysmedia/cdbr:
.ifdef ARM64_ISO
	dd if=/dev/zero of=sysmedia/cdbr bs=512 count=5760
	vnconfig vnd3 sysmedia/cdbr
	fdisk -iy -b "5744@16:c" vnd3
	newfs -t msdos /dev/rvnd3i
	mkdir arm64cdboot
	mount -o-l /dev/vnd3i arm64cdboot
	mkdir -p arm64cdboot/efi/boot
	cp /usr/mdec/BOOTAA64.EFI arm64cdboot/efi/boot/bootaa64.efi
	echo bootaa64.efi > arm64cdboot/efi/boot/startup.nsh
	umount arm64cdboot
	vnconfig -u vnd3
	rmdir arm64cdboot
.else
	-cat /usr/mdec/cdbr >sysmedia/cdbr
.endif

# create a UEFI boot image for amd64 if UEFI applications exist
#
.ifdef EFICD
sysmedia/eficdboot: /usr/mdec/BOOTIA32.EFI /usr/mdec/BOOTX64.EFI
	rm -rf eficdboot
	mkdir -p eficdboot/efi/boot
	cp /usr/mdec/BOOTIA32.EFI /usr/mdec/BOOTX64.EFI eficdboot/efi/boot/.
	makefs -t msdos -o create_size=$(EFICDBOOT_SIZE) sysmedia/eficdboot eficdboot
	rm -rf eficdboot
.endif

sysmedia/etc/boot.conf: lib/boot.conf.$(ARCH)
	[ -d sysmedia/etc ] || mkdir sysmedia/etc
	cp lib/boot.conf.$(ARCH) sysmedia/etc/boot.conf

# ffsimg's contents must be identical to staging's one
#
sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg: sync

#========================================
# merging a RAM disk root filesystem image
# into a kernel
#
$(KERN_SP): rdroot.ffsimg $(BSD_SP)
	$(MAKE) open-sysmedia
	cp $(BSD_SP) bsd
	rdsetroot bsd rdroot.ffsimg
	$(COMPRESS) -c9 bsd > $(KERN_SP)
	rm bsd
	$(MAKE) close-sysmedia

$(KERN_MP): rdroot.ffsimg $(BSD_MP)
	$(MAKE) open-sysmedia
	cp $(BSD_MP) bsd.mp
	rdsetroot bsd.mp rdroot.ffsimg
	$(COMPRESS) -c9 bsd.mp > $(KERN_MP)
	rm bsd.mp
	$(MAKE) close-sysmedia

#========================================
# stuffs on kernel compilation
#
.PHONY: kernconfig
kernconfig:
	(cd $(KERNSRC)/conf &&\
	 cp GENERIC RDROOT &&\
         patch < $(BLDDIR)/lib/RDROOT.diff)
	(cd $(KERNSRC)/arch/$(ARCH)/conf &&\
	 cp GENERIC RDROOT &&\
         patch < $(BLDDIR)/lib/RDROOT.$(ARCH).diff &&\
	 cp GENERIC.MP RDROOT.MP &&\
         patch < $(BLDDIR)/lib/RDROOT.MP.$(ARCH).diff &&\
         config RDROOT && config RDROOT.MP)

.PHONY: kernclean
kernclean:
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT &&\
         make clean)
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP &&\
         make clean)

.PHONY: kern
kern: $(BSD_SP) $(BSD_MP)

$(BSD_SP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT &&\
         make $(KERNOPT))

$(BSD_MP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP &&\
         make $(KERNOPT))

# reorder kernel at next compilation
#
.PHONY: kernreset
kernreset:
	rm -f $(BSD_SP) $(BSD_SPG) $(BSD_SPV)\
	      $(BSD_MP) $(BSD_MPG) $(BSD_MPV)

#========================================
# generating RAM disk root filesystem image
#
.if exists(rdroot/boottmp/rc)
BOOTTMPS != echo rdroot/boottmp/*
.endif

rdroot.ffsimg: /usr/src/etc/etc.$(ARCH)/MAKEDEV\
               /usr/src/etc/etc.$(ARCH)/login.conf\
               lib/bootbin/obj/bootbin $(BOOTTMPS)
	$(MAKE) close-rdroot
#
# create rdroot.ffsimg
#
	./lib/setup_fsimg.sh rdroot.ffsimg 4M 1500 '-b 4096 -f 512'
	         # parameters for minimum resources ^^^^^^^^^^^^^^
	vnconfig vnd0 rdroot.ffsimg
	mount /dev/vnd0a /mnt
	(cd rdroot && pax -rwvpe . /mnt/.)
#
# setup inside rdroot.ffsimg
#
	ln -sf boottmp /mnt/bin
	ln -sf boottmp /mnt/etc
	ln -sf boottmp /mnt/sbin
	mkdir -p /mnt/{dev,fuguita,mnt,ram,sysmedia,sysmedia-iso,tmp}
	chmod go-rwx /mnt/sysmedia-iso
	chmod 1777 /mnt/tmp
	cd /mnt/dev && cp -p /usr/src/etc/etc.$$(uname -m)/MAKEDEV . && sh ./MAKEDEV all vnd4 vnd5
#       datasize in login.conf determines the max limit of mfs
	sed '/^daemon:/,/:tc=default:/ s/:datasize=[^:][^:]*:/:datasize=infinity:/'\
	    /usr/src/etc/etc.$(ARCH)/login.conf > /mnt/boottmp/login.conf
	cp -p lib/bootbin/obj/bootbin /mnt/boottmp
	for prog in disklabel halt init ln mount mount_cd9660 mount_ext2fs\
	            mount_ffs mount_mfs mount_msdos mount_ntfs mount_vnd newfs\
	            reboot sed sleep swapctl swapon sysctl umount vnconfig; do\
	    ln -f /mnt/boottmp/bootbin /mnt/boottmp/$$prog;\
	done
	rm -f /mnt/boottmp/ksh /mnt/boottmp/sh
	cp -p /bin/ksh /mnt/boottmp/.
	ln /mnt/boottmp/ksh /mnt/boottmp/sh
	umount /mnt || { sync; sleep 15; sync; umount /mnt; }
	vnconfig -u vnd0

# build a crunched binary
#
lib/bootbin/obj/bootbin:
	cd lib/bootbin;\
	make

#========================================
# vnconfig related stuffs
#

# to faster access
#
MNT_OPT = -o async,noatime

.PHONY: open-rdroot
open-rdroot:
	@if vnconfig -l | grep -q '^vnd0: not in use'; then\
	    vnconfig vnd0 rdroot.ffsimg;\
	fi
	@if vnconfig -l | grep -q '^vnd0: covering ' &&\
	    ! mount | grep -q '^/dev/vnd0a on '; then\
	    mount $(MNT_OPT) /dev/vnd0a /mnt;\
	fi

.PHONY: close-rdroot
close-rdroot:
	@if mount | grep -q '^/dev/vnd0a on '; then\
	    umount /dev/vnd0a || { sync; sleep 15; sync; umount /dev/vnd0a; };\
	fi
	@if vnconfig -l | grep -q '^vnd0: covering '; then\
	    vnconfig -u vnd0;\
	fi

# if sysmedia.img exists , mount the vnode vnd1 bound to it.
# otherwise, work in directory sysmedia
#
.PHONY: open-sysmedia
open-sysmedia:
	@if [ -f sysmedia.img ];\
	then\
	    if vnconfig -l | grep -q '^vnd1: not in use'; then\
	        vnconfig vnd1 sysmedia.img;\
	    fi;\
	    if vnconfig -l | grep -q '^vnd1: covering ' &&\
	       ! mount | grep -q '^/dev/vnd1a on '; then\
	        mount $(MNT_OPT) /dev/vnd1a $(BLDDIR)/sysmedia;\
	    fi;\
	fi

.PHONY: close-sysmedia
close-sysmedia: close-fuguita
	@if [ -f sysmedia.img ];\
	then\
	    if mount | grep -q '^/dev/vnd1a on '; then\
	        umount /dev/vnd1a || { sync; sleep 15; sync; umount /dev/vnd1a; };\
	    fi;\
	    if vnconfig -l | grep -q '^vnd1: covering '; then\
	        vnconfig -u vnd1;\
	    fi;\
	fi

.PHONY: open-fuguita
open-fuguita: open-sysmedia
	@if vnconfig -l | grep -q '^vnd2: not in use'; then\
	    vnconfig vnd2 $(BLDDIR)/sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg;\
	fi
	@if vnconfig -l | grep -q '^vnd2: covering ' &&\
	    ! mount | grep -q '^/dev/vnd2a on '; then\
	    mount $(MNT_OPT) /dev/vnd2a $(BLDDIR)/fuguita;\
	fi

.PHONY: close-fuguita
close-fuguita:
	@if mount | grep -q '^/dev/vnd2a on '; then\
	    umount /dev/vnd2a || { sync; sleep 15; sync; umount /dev/vnd2a; };\
	fi
	@if vnconfig -l | grep -q '^vnd2: covering '; then\
	    vnconfig -u vnd2;\
	fi

.PHONY: close-all
close-all:
	-$(MAKE) close-rdroot
	-$(MAKE) close-sysmedia

# create fundamental files and directories
#
.PHONY: init
init:
	$(MAKE) reset
	mkdir -p sys install_sets install_pkgs install_patches fuguita sysmedia
	if [ ! -d sys/arch/$(ARCH) ]; then (cd sys && lndir /usr/src/sys); fi
	cd lib/bootbin;\
	make obj;\
	cd special;\
	ln -sf /usr/src/distrib/special/Makefile.inc .;\
	make obj
.if exists(sysmedia-$(VERSION)-$(ARCH).img.gz)
	$(COMPRESS) -dc sysmedia-$(VERSION)-$(ARCH).img.gz > sysmedia.img
.endif

# full compilation kernels
# and setup for RAM disk filesystem image
#
.PHONY: setup
setup:
	$(MAKE) kernconfig
	$(MAKE) kernclean
	$(MAKE) rdroot.ffsimg
	$(MAKE) imgs

# creating media.img
# and fuguita-REV-ARCH.ffsimg located in media.img (or media)
#
.PHONY: imgs
.ifdef CREATE_SYSMEDIA_IMG
# kernels are needed for get the size of media.img
imgs: staging $(BSD_SP) $(BSD_MP)
.else
imgs: staging
.endif
	./lib/create_imgs.sh
# an alternative under test
#	./lib/setupfs.sh sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg staging 16m

#========================================
# create staging directory
# and file tree which is modified for the Live System
#

# set files under install_*/*
#
STAGE_DEPENDS =
.for dir in install_sets install_pkgs install_patches
    files != ls $(dir) 2>/dev/null | grep -v '^\.' || true
.   for file in $(files)
        STAGE_DEPENDS += $(dir)/$(file)
.   endfor
.endfor

STAGE_DEPENDS += lib/global.conf.$(ARCH)

.if exists(lib/mode0symlinks.cpio.gz.$(ARCH))
STAGE_DEPENDS += lib/mode0symlinks.cpio.gz.$(ARCH)
.endif

.if exists(lib/usbfadm_postproc.sh.$(ARCH))
STAGE_DEPENDS += lib/usbfadm_postproc.sh.$(ARCH)
.endif

.PHONY: staging
staging: staging.time
staging.time: $(STAGE_DEPENDS)
	./lib/010_extract.sh
	./lib/020_modify_tree.sh
	touch staging.time

#========================================
# packaging controls
#
DISTCLEANFILES = rev.count sysmedia.img
DISTCLEANDIRS = staging fuguita sysmedia sys install_sets install_pkgs install_patches

.PHONY: distclean
distclean:
	$(MAKE) clean
	$(MAKE) rdclean
	rm -f $(DISTCLEANFILES)
	rm -rf $(DISTCLEANDIRS)

# reset revision sequece numnber to 1
#
.PHONY: reset
reset:
	echo 1 > rev.count

CLEANFILES = bsd bsd.mp livecd.iso sysmedia.time staging.time FuguIta-?.*-*-*.*.gz\
             $(BSD_SP) $(BSD_MP) trial_capa.img
CLEANDIRS = staging.*_* trial_capa eficdboot
.PHONY: clean
clean:
	$(MAKE) close-all
	rm -f $(CLEANFILES)
	rm -rf $(CLEANDIRS)

# remove all requisites to build RAM disk filesystem image
#
.PHONY: rdclean
rdclean:
	rm -rf rdroot.ffsimg
	cd lib/bootbin && rm -rf obj
	cd lib/bootbin/special && rm -f Makefile.inc
	cd lib/bootbin/special && rm -rf */obj

#========================================
# generate LiveUSB from LiveDVD
#
IMGMB = 2048# size of uncompressed LiveUSB in MB

.PHONY: dvd2usb
dvd2usb:
	pv $(FI).iso.gz | $(COMPRESS) -d -c > $(FI).iso
	dd if=/dev/zero bs=1m count=$(IMGMB) | pv -s $(IMGMB)M > $(FI).img
	vmctl start -cL -i1 -m2G -r $(FI).iso -d $(FI).img fi74
	vmctl start -cL -i1 -m2G -d $(FI).img fi74
	pv $(FI).img | $(COMPRESS) -9 -c > $(FI).img.gz

.PHONY: imgclean
imgclean:
	rm -f $(FI).img.gz $(FI).img $(FI).iso
