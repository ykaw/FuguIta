# Copyright (c) 2006--2021, Yoshihiro Kawamata
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

PROJNAME =FuguIta
VERSION !=uname -r
ARCH    !=uname -m
DATE    !=date +%Y%m%d
REVISION!=if [ -r revcount_cdmaster ]; then cat revcount_cdmaster; else echo 0; fi

FI_FILENAME=$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$(REVISION)
#VERSTAT=beta
VERSTAT=
AUTHOR=KAWAMATA, Yoshihiro <kaw@on.rim.or.jp>

CDR_DEV=cd0

USB_DEV=vnd1
USB_MNT=/mnt
USB_IMG=media.img

all:
	@echo /$(FI_FILENAME)/ - lets go

open-all: open-rdroot open-media open-fuguita

close-all: close-fuguita close-media close-rdroot

open-rdroot:
	-vnconfig vnd0 rdroot.img
	-mount /dev/vnd0a rdroot

close-rdroot:
	-umount rdroot
	-vnconfig -u vnd0

open-media:
	-vnconfig vnd1 media.img
	-mount /dev/vnd1a media

close-media:
	-umount media
	-vnconfig -u vnd1

open-fuguita:
	-vnconfig vnd2 media/fuguita-$(VERSION)-$(ARCH).ffsimg
	-mount /dev/vnd2a fuguita

close-fuguita:
	-umount fuguita
	-vnconfig -u vnd2

shrink: shrinkfiles zipfiles

shrinkfiles: filetypelist
	[ X$(BASEDIR) != X ]
	[ -d $(BASEDIR) ]
	grep 'not stripped' filetypes | cut -d: -f1 | xargs strip
	grep 'current ar archive' filetypes | cut -d: -f1 | xargs rm -f

filetypelist:
	[ X$(BASEDIR) != X ]
	[ -d $(BASEDIR) ]
	-find $(BASEDIR) -type f -print0 | xargs -0 file > filetypes 2> filetypes.err

zipfiles:
	[ X$(BASEDIR) != X ]
	[ -d $(BASEDIR) ]
	-cd $(BASEDIR)/man && /usr/fuguita/sbin/compress_man.sh
	-cd $(BASEDIR)/share/doc && find . -type f -print0 | xargs -0 gzip -v9
	-cd $(BASEDIR)/info && find . -type f \! -name dir -print0 | xargs -0 gzip -v9
	-cd $(BASEDIR)/share/gtk-doc && find . -type f -print0 | xargs -0 gzip -v9

hyb:
	make open-fuguita
	echo "$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" > fuguita/usr/fuguita/version
	make close-fuguita

	mkhybrid -a -R -L -l -d -D -N \
		-o livecd.iso \
		-v -v \
		-A "FuguIta - OpenBSD Live System" \
		-P "Copyright (c) `date +%Y` KAWAMATA Yoshihiro" \
		-p "KAWAMATA Yoshihiro, http://fuguita.org/" \
		-V "$(PROJNAME)-$(VERSION)-$(ARCH)-$(DATE)$$(($(REVISION)+1))" \
		-b cdbr \
		-c boot.catalog \
		media \
	&& echo $$(($(REVISION)+1)) > revcount_cdmaster

boot: bsd.rdcd bsd.mp.rdcd lib/cdbr lib/cdboot
	cp lib/cdbr lib/cdboot media/.
	[ -d media/etc ] || mkdir media/etc
	cp lib/boot.conf media/etc/.
	: '[ -d media/sbin ] || mkdir media/sbin'
	: 'cp -p /sbin/vnconfig media/sbin; strip media/sbin/vnconfig'
	: '/usr/mdec/installboot -v media/boot /usr/mdec/biosboot vnd1'

bsd.rdcd: bsd.orig rdroot.img
	cp bsd.orig bsd
	rdsetroot bsd rdroot.img
	gzip -c9 bsd > media/bsd-fi

bsd.mp.rdcd: bsd.mp.orig rdroot.img
	cp bsd.mp.orig bsd.mp
	rdsetroot bsd.mp rdroot.img
	gzip -c9 bsd.mp > media/bsd-fi.mp

cdemu:
	/usr/local/bin/qemu-system-x86_64 -m 256 -monitor stdio -cdrom livecd.iso -boot d

usbemu:
	/usr/local/bin/qemu-system-x86_64 -m 256 -monitor stdio -hda media.img c -boot c

hddinstall:
	cat media/bsd-fi    > /bsd-fi
	cat media/bsd-fi.mp > /bsd-fi.mp
	dd if=livecd.iso of=/ISO/$(FI_FILENAME).iso bs=65535k

gz: cdgz usbgz

cdgz:
	ln livecd.iso $(FI_FILENAME)$(VERSTAT).iso
	gzip -v9 $(FI_FILENAME)$(VERSTAT).iso

cdxz:
	dd if=livecd.iso of=$(FI_FILENAME)$(VERSTAT).iso bs=65536k
	xz -v9 $(FI_FILENAME)$(VERSTAT).iso

usbgz:
	gzip -cv9 media.img > $(FI_FILENAME)$(VERSTAT).usbimg.gz

cdrburn: cdrclean cdburn

cdrclean:
	cdio -v -f /dev/r$(CDR_DEV)c blank

cdburn:
	cdio -v -f /dev/r$(CDR_DEV)c tao livecd.iso

clean:
	rm -f bsd bsd.mp livecd.iso $(FI_FILENAME).iso.gz $(FI_FILENAME).usbimg.gz

contall:
	-make close-all
	rm -f /ISO/FuguIta-*-$(ARCH)-?????????.iso
	make open-media
	make boot
	make hyb
	make hddinstall
	-make close-all
	-make cdrburn
	make cdgz

#======================================================================

#usbfill:
#	mount /dev/$(USB_DEV)a $(USB_MNT)
#	-[ -d $(USB_MNT)/tmp ] || mkdir $(USB_MNT)/tmp && chmod 1777 $(USB_MNT)/tmp
#	-dd if=/dev/zero of=$(USB_MNT)/tmp/fill bs=65536k
#	rm -f $(USB_MNT)/tmp/fill
#	umount $(USB_MNT)
#	mount /dev/$(USB_DEV)d $(USB_MNT)
#	-dd if=/dev/zero of=$(USB_MNT)/livecd-config/fill bs=65536k
#	rm -f $(USB_MNT)/livecd-config/fill
#	umount $(USB_MNT)
