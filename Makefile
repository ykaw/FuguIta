# Copyright (c) 2006--2023, Yoshihiro Kawamata
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


#========================================
# global definitions
#
PROJNAME =FuguIta
VERSION != uname -r
VER     != uname -r | tr -d .
ARCH    != uname -m
DATE    != date +%Y%m%d
REV     != if [[ -r rev.count ]] ; then\
               rev=$$(cat rev.count);\
           else\
               rev=1;\
           fi;\
           [[ $$rev -le 0 ]] && rev=1;\
           echo $$rev
#VERSTAT=beta
VERSTAT =
AUTHOR = Yoshihiro Kawamata <kaw@on.rim.or.jp>
FIBASE = $(VERSION)-$(ARCH)-$(DATE)$(REV)$(VERSTAT)
FI = $(PROJNAME)-$(FIBASE)

BLDDIR != realpath $$(pwd)

#========================================
# final product
#
.if $(ARCH) == arm64
all: usbgz
.else
all: isogz
.endif

# for i386/amd64
#
.PHONY: isogz
isogz: $(FI).iso.gz
$(FI).iso.gz: livecd.iso
	@echo generating $(FI).iso.gz
	@pv livecd.iso | gzip -9f -o $(FI).iso.gz
	echo $$(($(REV)+1)) > rev.count

# now, only for arm64
#
.PHONY: usbgz
usbgz: boot sync
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-fuguita
	@echo generating $(FI).img.gz
	@pv sysmedia.img | gzip -9f -o $(FI).img.gz
	echo $$(($(REV)+1)) > rev.count

# sync staging to sysmedia/fuguita-*.ffsimg
#
.PHONY: sync
sync: sync.time
sync.time: staging.time
	$(MAKE) open-fuguita
	# equalize fuguita directory to staging:
	# When applying a patch and resynchronizing, media.img may overflow,
	# so in that case, delete some large files and rerun rsync.
	cd staging &&\
	if ! rsync -avxH --delete . ../fuguita/.; then\
	    find ../fuguita/ -type f -size +4096 -print | xargs rm;\
	    rsync -avxH --delete . ../fuguita/.;\
	fi
	$(MAKE) close-fuguita
	touch sync.time

# generate an ISO file
#
livecd.iso: boot sync
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-fuguita
	mkhybrid -a -R -L -l -d -D -N\
		-o livecd.iso\
		-v -v\
		-A "FuguIta: OpenBSD-based Live System"\
		-P "Copyright (c) `date +%Y` Yoshihiro Kawamata"\
		-p "Yoshihiro Kawamata, https://fuguita.org/"\
		-V "$(FI)"\
		-b cdbr\
		-c boot.catalog\
		sysmedia\

#========================================
# stuffs on boot loaders and kernels
#
.PHONY: boot
boot:
	$(MAKE) kernreset
	$(MAKE) kern
	$(MAKE) open-sysmedia
	cp /usr/mdec/cdbr sysmedia/.   || touch sysmedia/cdbr
	cp /usr/mdec/cdboot sysmedia/. || touch sysmedia/cdboot
	cp /usr/mdec/boot sysmedia/.   || touch sysmedia/boot
	[ -d sysmedia/etc ] || mkdir sysmedia/etc
	cp lib/boot.conf.$(ARCH) sysmedia/etc/boot.conf
	$(MAKE) close-sysmedia

sysmedia/bsd-fi: rdroot.ffsimg $(KERN_SP)
	$(MAKE) open-sysmedia
	cp $(KERN_SP) bsd
	rdsetroot bsd rdroot.ffsimg
	gzip -c9 bsd > sysmedia/bsd-fi
	-rm bsd
	$(MAKE) close-sysmedia

sysmedia/bsd-fi.mp: rdroot.ffsimg $(KERN_MP)
	$(MAKE) open-sysmedia
	cp $(KERN_MP) bsd.mp
	rdsetroot bsd.mp rdroot.ffsimg
	gzip -c9 bsd.mp > sysmedia/bsd-fi.mp
	-rm bsd.mp
	$(MAKE) close-sysmedia

#========================================
# stuffs on kernel compilation
#
KERNSRC  = $(BLDDIR)/sys
KERNOPT  = -j2
KERN_SP  = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/bsd
KERN_MP  = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd
KERN_SGP = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/gapdummy.o
KERN_MGP = $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/gapdummy.o

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
kern: $(KERN_SP) $(KERN_MP)

$(KERN_SP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT &&\
         make $(KERNOPT))

$(KERN_MP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP &&\
         make $(KERNOPT))

# This is because it causes kernel reordering by hand.
#
.PHONY: kernreset
kernreset:
	rm -f $(KERN_SP) $(KERN_SGP) $(KERN_MP) $(KERN_MGP)

#========================================
# generating RAM disk root filesystem image
#
.if exists(rdroot/boottmp/rc)
BOOTTMPS != echo rdroot/boottmp/*
.endif

rdroot.ffsimg: /usr/src/etc/etc.$(ARCH)/MAKEDEV /usr/src/etc/etc.$(ARCH)/login.conf lib/bootbin/bootbin $(BOOTTMPS)
	$(MAKE) close-rdroot
	#
	# create rdroot.ffsimg
	#
	./lib/setup_fsimg.sh rdroot.ffsimg 1900K 1500 '-b 4096 -f 512'
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
	sed '/^daemon:/,/:tc=default:/ s/:datasize=[^:][^:]*:/:datasize=infinity:/'\
	    /usr/src/etc/etc.$(ARCH)/login.conf > /mnt/boottmp/login.conf
	cp -p lib/bootbin/bootbin /mnt/boottmp
	for prog in disklabel halt init ksh ln mount mount_cd9660 mount_ext2fs\
	            mount_ffs mount_mfs mount_msdos mount_ntfs mount_vnd newfs\
	            reboot sed sh sleep swapctl swapon sysctl umount vnconfig; do\
	    ln -f /mnt/boottmp/bootbin /mnt/boottmp/$$prog;\
	done
	sync
	umount /mnt
	vnconfig -u vnd0

lib/bootbin/bootbin:
	cd lib/bootbin && sh ../doit_bootbin

#========================================
# vnconfig related stuffs
#
.PHONY: open-rdroot
open-rdroot:
	@if vnconfig -l | grep -q '^vnd0: not in use'; then\
	    vnconfig vnd0 rdroot.ffsimg;\
	fi
	@if vnconfig -l | grep -q '^vnd0: covering '; then\
	    mount /dev/vnd0a /mnt;\
	fi

.PHONY: close-rdroot
close-rdroot:
	@if mount | grep -q '^/dev/vnd0a on '; then\
	    sync;\
	    umount /dev/vnd0a;\
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
	    if vnconfig -l | grep -q '^vnd1: covering '; then\
	        mount /dev/vnd1a $(BLDDIR)/sysmedia;\
	    fi;\
	fi

.PHONY: close-sysmedia
close-sysmedia: close-fuguita
	@if [ -f sysmedia.img ];\
	then\
	    if mount | grep -q '^/dev/vnd1a on '; then\
	        sync;\
	        umount /dev/vnd1a;\
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
	@if vnconfig -l | grep -q '^vnd2: covering '; then\
	    mount /dev/vnd2a $(BLDDIR)/fuguita;\
	fi

.PHONY: close-fuguita
close-fuguita:
	@if mount | grep -q '^/dev/vnd2a on '; then\
	    sync;\
	    umount /dev/vnd2a;\
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
	cd lib;\
	mkdir -p bootbin;\
	cd special;\
	make obj;\
	for prog in init mount_* newfs swapctl sysctl vnconfig; do\
	    (cd $$prog && ln -sf /usr/src/sbin/$$prog/*.[ch] .);\
	done

# full compilation kernels
# and setup for RAM disk filesystem image
#
.PHONY: setup
setup:
	$(MAKE) kernconfig
	$(MAKE) kernclean
	$(MAKE) rdroot.ffsimg
.if $(ARCH) != arm64
	$(MAKE) imgs
.endif


# creating media.img
# and fuguita-REV-ARCH.ffsimg located in media.img (or media)
#
.PHONY: imgs
imgs: staging
	./lib/create_imgs.sh

#========================================
# create staging directory
# and file tree which is modified for the Live System
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

# On arm64, cannot generate automatically yet
#
DISTCLEANFILES = rev.count
.if $(ARCH) == arm64
.PRECIOUS: sysmedia.img
.else
DISTCLEANFILES += sysmedia.img
.endif
DISTCLEANDIRS = staging fuguita sysmedia sys install_sets install_pkgs install_patches

.PHONY: distclean
distclean:
	$(MAKE) clean
	rm -f $(DISTCLEANFILES)
	rm -rf $(DISTCLEANDIRS)
	$(MAKE) rdclean

.PHONY: reset
reset:
	echo 1 > rev.count

CLEANFILES = bsd bsd.mp livecd.iso staging.time sync.time FuguIta-?.?-*-*.*.gz\
             $(KERN_SP) $(KERN_SGP) $(KERN_MP) $(KERN_MGP)# to build reorderd kernels
CLEANDIRS = staging.*_*
.PHONY: clean
clean:
	$(MAKE) close-all
	rm -f $(CLEANFILES)
	rm -rf $(CLEANDIRS)

.PHONY: rdclean
rdclean:
	rm -f rdroot.ffsimg lib/bootbin/!(CVS)
	cd lib/special && $(MAKE) clean
	rm -rf lib/special/*/obj
	find lib/special -type l -print | xargs rm -f

#========================================
# generate LiveUSB from LiveDVD
#
IMGMB = 2048 # size of uncompressed LiveUSB in MB

.PHONY: dvd2usb
dvd2usb: $(FIBASE).img.gz

$(FIBASE).img.gz:
	pv $(FIBASE).iso.gz | gzip -d -o $(FIBASE).iso
	dd if=/dev/zero bs=1m count=$(IMGMB) | pv -s $(IMGMB)M > $(FIBASE).img
	vmctl start -cL -i1 -m2G -r $(FIBASE).iso -d $(FIBASE).img fi74
	vmctl start -cL -i1 -m2G -d $(FIBASE).img fi74
	pv $(FIBASE).img | gzip -o $(FIBASE).img.gz -9

.PHONY: imgclean
imgclean:
	rm -f $(FIBASE).img.gz $(FIBASE).img $(FIBASE).iso
