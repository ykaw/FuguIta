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
VERSION !=uname -r
VER     !=uname -r | tr -d .
ARCH    !=uname -m
DATE    !=date +%Y%m%d
REV     != if [[ -r rev.count ]] ; then\
               rev=$$(cat rev.count);\
           else\
               rev=1;\
           fi;\
           [[ $$rev -le 0 ]] && rev=1;\
           echo $$rev
#VERSTAT=beta
VERSTAT=
AUTHOR=Yoshihiro Kawamata <kaw@on.rim.or.jp>
FIBASE=$(VERSION)-$(ARCH)-$(DATE)$(REV)$(VERSTAT)
FI=$(PROJNAME)-$(FIBASE)

FIBUILD!=pwd
KERNSRC=$(FIBUILD)/sys
KERNOPT=-j2
KERN_SP=$(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/bsd
KERN_MP=$(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd

#========================================
# final product
#
gz: $(FI).iso.gz
$(FI).iso.gz: livecd.iso
	@echo generating $(FI).iso.gz
	@pv livecd.iso | gzip -9f -o $(FI).iso.gz
	echo $$(($(REV)+1)) > rev.count

# now, only for arm64
#
usbgz: boot sync
	$(MAKE) close-all
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-all
	@echo generating $(FI).img.gz
	@pv sysmedia.img | gzip -9f -o $(FI).img.gz
	echo $$(($(REV)+1)) > rev.count

#========================================
# sync staging to sysmedia/fuguita-*.ffsimg
#
sync: sync.time
sync.time: staging
	$(MAKE) close-all
	$(MAKE) open-fuguita
	cd staging && \
	if ! rsync -avxH --delete . ../fuguita/.; then\
	    find ../fuguita/ -type f -size +4096 -print | xargs rm;\
	    rsync -avxH --delete . ../fuguita/.;\
	fi
	touch sync.time

#========================================
# generate an ISO file
#
livecd.iso: boot sync
	$(MAKE) close-all
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-fuguita
	mkhybrid -a -R -L -l -d -D -N \
		-o livecd.iso \
		-v -v \
		-A "FuguIta: OpenBSD-based Live System" \
		-P "Copyright (c) `date +%Y` Yoshihiro Kawamata" \
		-p "Yoshihiro Kawamata, https://fuguita.org/" \
		-V "$(FI)" \
		-b cdbr \
		-c boot.catalog \
		sysmedia \

#========================================
# stuffs on kernel generation
#
boot: force-build-kern
	$(MAKE) close-all
	$(MAKE) open-sysmedia
	cp /usr/mdec/cdbr sysmedia/.   || touch sysmedia/cdbr
	cp /usr/mdec/cdboot sysmedia/. || touch sysmedia/cdboot
	cp /usr/mdec/boot sysmedia/.   || touch sysmedia/boot
	[ -d sysmedia/etc ] || mkdir sysmedia/etc
	cp lib/boot.conf.$(ARCH) sysmedia/etc/boot.conf

# to make kernels re-ordered
#
force-build-kern:
	rm -f $(KERN_SP) $(KERN_MP)
	$(MAKE) sysmedia/bsd-fi sysmedia/bsd-fi.mp

sysmedia/bsd-fi: rdroot.ffsimg $(KERN_SP)
	$(MAKE) close-all
	$(MAKE) open-sysmedia
	cp $(KERN_SP) bsd
	rdsetroot bsd rdroot.ffsimg
	gzip -c9 bsd > sysmedia/bsd-fi
	-rm bsd

sysmedia/bsd-fi.mp: rdroot.ffsimg $(KERN_MP)
	$(MAKE) close-all
	$(MAKE) open-sysmedia
	cp $(KERN_MP) bsd.mp
	rdsetroot bsd.mp rdroot.ffsimg
	gzip -c9 bsd.mp > sysmedia/bsd-fi.mp
	-rm bsd.mp

.if exists(rdroot/boottmp/rc)
    BOOTTMPS != echo rdroot/boottmp/*
.endif

rdroot.ffsimg: /usr/src/etc/etc.$(ARCH)/MAKEDEV lib/login.conf.$(ARCH) lib/bootbin/bootbin $(BOOTTMPS)
	$(MAKE) close-all
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
	cp -p lib/login.conf.$$(uname -m) /mnt/boottmp/.
	cp -p lib/bootbin/bootbin /mnt/boottmp
	for prog in disklabel halt init ksh ln mount mount_cd9660 mount_ext2fs \
	            mount_ffs mount_mfs mount_msdos mount_ntfs mount_vnd newfs \
	            reboot sed sh sleep swapctl swapon sysctl umount vnconfig; do\
	    ln -f /mnt/boottmp/bootbin /mnt/boottmp/$$prog;\
	done
	umount /mnt
	vnconfig -u vnd0

lib/bootbin/bootbin:
	cd lib/bootbin && sh ../doit_bootbin

#========================================
# vnconfig related stuffs
#
close-all: close-sysmedia close-rdroot

open-rdroot:
	@if mount | grep -q '^/dev/vnd0a on '; \
	then echo rdroot already opened;\
	else vnconfig vnd0 rdroot.ffsimg ; mount /dev/vnd0a /mnt; fi

close-rdroot:
	@if mount | grep -q '^/dev/vnd0a on '; \
	then umount /mnt; vnconfig -u vnd0; \
	else echo rdroot already closed; fi

open-sysmedia:
	@if [ -f sysmedia.img ]; then \
	    if mount | grep -q '$(FIBUILD)/sysmedia type '; then \
	        echo media already opened; \
	    else \
	        vnconfig vnd1 sysmedia.img; \
	        mount -o async,noatime /dev/vnd1a sysmedia; \
	    fi; \
	fi

close-sysmedia:
	@if [ -f sysmedia.img ]; then \
	    if mount | grep -q '$(FIBUILD)/sysmedia type '; then \
	        $(MAKE) close-fuguita; \
	        umount sysmedia; \
	        vnconfig -u vnd1; \
	    else \
	        echo media already closed; \
	    fi; \
	fi

open-fuguita: open-sysmedia
	@if mount | grep -q '$(FIBUILD)/fuguita type '; \
	then echo fuguita already opened;\
	else vnconfig vnd2 $(FIBUILD)/sysmedia/fuguita-$(VERSION)-$(ARCH).ffsimg ; mount -o async,noatime /dev/vnd2a fuguita; fi

close-fuguita:
	@if mount | grep -q '$(FIBUILD)/fuguita type '; \
	then umount fuguita; vnconfig -u vnd2; \
	else echo fuguita already closed; fi

#========================================
# setup system filetree
#
init:
	mkdir -p sys install_sets install_pkgs install_patches fuguita sysmedia
	if [ ! -d sys/arch/$(ARCH) ]; then (cd sys && lndir /usr/src/sys); fi
	cd lib; \
	mkdir -p bootbin; \
	cd special; \
	make obj; \
	for prog in init mount_* newfs swapctl sysctl vnconfig; do \
	    (cd $$prog && ln -sf /usr/src/sbin/$$prog/*.[ch] .); \
	done

setup:
	$(MAKE) kernconfig
	$(MAKE) kernclean
	$(MAKE) kern
	$(MAKE) rdroot.ffsimg
	$(MAKE) imgs

kernconfig:
	(cd $(KERNSRC)/conf && \
	 cp GENERIC RDROOT && \
         patch < $(FIBUILD)/lib/RDROOT.diff)
	(cd $(KERNSRC)/arch/$(ARCH)/conf && \
	 cp GENERIC RDROOT && \
         patch < $(FIBUILD)/lib/RDROOT.$(ARCH).diff && \
	 cp GENERIC.MP RDROOT.MP && \
         patch < $(FIBUILD)/lib/RDROOT.MP.$(ARCH).diff && \
         config RDROOT && config RDROOT.MP )

kernclean:
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT && \
         make obj && make clean)
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP && \
         make obj && make clean)

kern: $(KERN_SP) $(KERN_MP)

$(KERN_SP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT && \
         make obj && make config && make $(KERNOPT))

$(KERN_MP):
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP && \
         make obj && make config && make $(KERNOPT))

imgs: staging
	$(MAKE) close-all
	./lib/create_imgs.sh

.if exists(install_sets/base$(VER).tgz)
    STAGE_FILES != ls -1d install_*/*
.endif

STAGE_FILES += lib/global.conf.$(ARCH)
.if exists(lib/mode0symlinks.cpio.gz.$(ARCH))
    STAGE_FILES += lib/mode0symlinks.cpio.gz.$(ARCH)
.endif
.if exists(lib/usbfadm_postproc.sh.$(ARCH))
    STAGE_FILES += lib/usbfadm_postproc.sh.$(ARCH)
.endif

staging: staging.time
staging.time: $(STAGE_FILES)
	./lib/010_extract.sh
	./lib/020_modify_tree.sh
	touch staging.time

#========================================
# packaging controls
#

# On arm64, cannot generate automatically yet
#
.if $(ARCH) == arm64
    DISTCLEANFILES=
    .PRECIOUS: sysmedia.img
.else
    DISTCLEANFILES=sysmedia.img
.endif
DISTCLEANDIRS=staging fuguita sysmedia sys install_sets install_pkgs install_patches

distclean:
	$(MAKE) reset
	$(MAKE) clean
	rm -f $(DISTCLEANFILES)
	rm -rf $(DISTCLEANDIRS)
	$(MAKE) rdclean

reset:
	rm -f rev.count

CLEANFILES=bsd bsd.mp livecd.iso staging.time sync.time FuguIta-?.?-*-*.*.gz
CLEANDIRS=staging.*_*
clean:
	$(MAKE) close-all
	rm -f $(CLEANFILES)
	rm -rf $(CLEANDIRS)

rdclean:
	rm -f rdroot.ffsimg lib/bootbin/!(CVS)
	cd lib/special && $(MAKE) clean
	rm -rf lib/special/*/obj
	find lib/special -type l -print | xargs rm -f

#========================================
# generate LiveUSB from LiveDVD
#
IMGMB=2048

.PHONY: imggz imgclean

imggz: $(FI).img.gz

$(FI).img.gz:
	pv $(FI).iso.gz | gzip -d -o $(FI).iso
	dd if=/dev/zero bs=1m count=$(IMGMB) | pv -s $(IMGMB)M > $(FI).img
	vmctl start -cL -i1 -m2G -r $(FI).iso -d $(FI).img fi74
	vmctl start -cL -i1 -m2G -d $(FI).img fi74
	pv $(FI).img | gzip -o $(FI).img.gz -9

imgclean:
	rm -f $(FI).img.gz $(FI).img $(FI).iso

#========================================
# for test
#
.if $(ARCH) == i386
SAY=yes
.else
SAY=no
.endif

maketest:
	@echo $(SAY)
