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
	mkdir -p fuguita sysmedia rdroot sys install_sets install_pkgs install_patches
	if [ ! -d sys/arch/$(ARCH) ]; then (cd sys && lndir /usr/src/sys); fi

setup:
	$(MAKE) kernconfig
	$(MAKE) kernclean
	$(MAKE) kern
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
usbgz: boot sync
	$(MAKE) close-all
	$(MAKE) open-fuguita
	echo "$(FIBASE)" > fuguita/usr/fuguita/version
	$(MAKE) close-all
	@echo generating $(FI).img.gz
	@pv sysmedia.img | gzip -9f -o $(FI).img.gz
	echo $$(($(REV)+1)) > rev.count

distclean:
	$(MAKE) clean
	$(MAKE) reset
	rm -f sysmedia.img
	rm -rf staging fuguita sysmedia rdroot sys install_sets install_pkgs install_patches

clean:
	$(MAKE) close-all
	rm -f bsd bsd.mp livecd.iso staging.time sync.time FuguIta-?.?-*-*.*.gz
	rm -rf staging.*_*

reset:
	rm -f rev.count

#========================================
# generate LiveUSB from LiveDVD
#
IMGMB=2048

.PHONY: imggz imgclean

imggz: $(FI).img.gz

$(FI).img.gz:
	pv $(FI).iso.gz | gzip -d -o $(FI).iso
	dd if=/dev/zero bs=1m count=$(IMGMB) | pv -s $(IMGMB)M > $(FI).img
	doas vmctl start -cL -i1 -m2G -r $(FI).iso -d $(FI).img fi74
	doas vmctl start -cL -i1 -m2G -d $(FI).img fi74
	pv $(FI).img | gzip -o $(FI).img.gz -9

imgclean:
	rm -f $(FI).img.gz $(FI).img $(FI).iso
