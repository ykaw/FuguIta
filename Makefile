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

PROJNAME =FuguIta
VERSION !=uname -r
ARCH    !=uname -m
DATE    !=date +%Y%m%d
REVISION!=if [ -r revcount_cdmaster ]; then cat revcount_cdmaster; else echo 0; fi

#VERSTAT=beta
VERSTAT=
AUTHOR=Yoshihiro Kawamata <kaw@on.rim.or.jp>

FIBUILD!=pwd
KERNSRC=$(FIBUILD)/sys
MAKEOPT=-j2

all:
	@echo /$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$(REVISION)/ - lets go

doall: kern stage imgs sync iso gz


#========================================
# vnconfig related stuffs

close-all: close-media close-rdroot

open-rdroot:
	@if mount | grep -q '$(FIBUILD)/rdroot type '; \
	then echo rdroot already opened;\
	else vnconfig vnd0 rdroot.img ; mount /dev/vnd0a rdroot; fi

close-rdroot:
	@if mount | grep -q '$(FIBUILD)/rdroot type '; \
	then umount rdroot; vnconfig -u vnd0; \
	else echo rdroot already closed; fi

open-media:
	@if mount | grep -q '$(FIBUILD)/media type '; \
	then echo media already opened;\
	else vnconfig vnd1 media.img ; mount -o async,noatime /dev/vnd1a media; fi

close-media:
	@if mount | grep -q '$(FIBUILD)/media type '; \
	then make close-fuguita; umount media; vnconfig -u vnd1; \
	else echo media already closed; fi

open-fuguita:
	make open-media
	@if mount | grep -q '$(FIBUILD)/fuguita type '; \
	then echo fuguita already opened;\
	else vnconfig vnd2 $(FIBUILD)/media/fuguita-$(VERSION)-$(ARCH).ffsimg ; mount -o async,noatime /dev/vnd2a fuguita; fi

close-fuguita:
	@if mount | grep -q '$(FIBUILD)/fuguita type '; \
	then umount fuguita; vnconfig -u vnd2; \
	else echo fuguita already closed; fi

#========================================
# setup system filetree

stage:
	./lib/010_extract.sh
	./lib/020_modify_tree.sh

imgs:
	make close-all
	./lib/create_imgs.sh

sync:
	make close-all
	make open-fuguita
	echo "$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" > staging/usr/fuguita/version
	(cd staging && rsync -avxH --delete . ../fuguita/.)

syncback:
	make close-all
	make open-fuguita
	(cd fuguita && rsync -avxH --delete . ../staging/.)

#========================================
# generate an ISO file

hyb:
	make close-all
	make open-fuguita
	echo "$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" > fuguita/usr/fuguita/version
	make close-fuguita

	mkhybrid -a -R -L -l -d -D -N \
		-o livecd.iso \
		-v -v \
		-A "FuguIta: OpenBSD-based Live System" \
		-P "Copyright (c) `date +%Y` Yoshihiro Kawamata" \
		-p "Yoshihiro Kawamata, https://fuguita.org/" \
		-V "$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" \
		-b cdbr \
		-c boot.catalog \
		media \
	&& echo $$(($(REVISION)+1)) > revcount_cdmaster

#========================================
# stuffs on kernel generation

boot: media/bsd-fi media/bsd-fi.mp
	make close-all
	make open-media
	cp /usr/mdec/cdbr media/.   || touch media/cdbr
	cp /usr/mdec/cdboot media/. || touch media/cdboot
	cp /usr/mdec/boot media/.   || touch media/boot
	[ -d media/etc ] || mkdir media/etc
	cp lib/boot.conf.$(ARCH) media/etc/boot.conf

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
kern:
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT && \
         make obj && make config && make $(MAKEOPT))
	(cd $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP && \
         make obj && make config && make $(MAKEOPT))

media/bsd-fi: rdroot.img $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/bsd
	make close-all
	make open-media
	cp $(KERNSRC)/arch/$(ARCH)/compile/RDROOT/obj/bsd bsd
	rdsetroot bsd rdroot.img
	gzip -c9 bsd > media/bsd-fi
	-rm bsd

media/bsd-fi.mp: rdroot.img $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd
	make close-all
	make open-media
	cp $(KERNSRC)/arch/$(ARCH)/compile/RDROOT.MP/obj/bsd bsd.mp
	rdsetroot bsd.mp rdroot.img
	gzip -c9 bsd.mp > media/bsd-fi.mp
	-rm bsd.mp

#========================================
# packaging controls

iso:
	make close-all
	make open-media
	make boot
	make hyb
	make close-all

gz:
	@echo generating $(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)`cat revcount_cdmaster`$(VERSTAT).iso.gz
	@pv livecd.iso | gzip -9f -o $(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)`cat revcount_cdmaster`$(VERSTAT).iso.gz

usbgz:
	make close-all
	@echo generating $(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$$((`cat revcount_cdmaster`+1))$(VERSTAT).img.gz
	@pv media.img | gzip -9f -o $(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$$((`cat revcount_cdmaster`+1))$(VERSTAT).img.gz

clean:
	make close-all
	rm -f bsd bsd.mp livecd.iso liveusb.img FuguIta-?.?-*-*.iso.gz FuguIta-?.?-*-*.img.gz

reset:
	make clean
	echo 0 > revcount_cdmaster
