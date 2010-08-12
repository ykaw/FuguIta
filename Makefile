# Copyright (c) 2006, 2007, 2008, 2009, Yoshihiro Kawamata
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
VERSION  =4.7
DATE    !=date +%Y%m%d
REVISION!=if [ -r revcount_cdmaster ]; then cat revcount_cdmaster; else echo 0; fi

FI_FILENAME=$(PROJNAME)-$(VERSION)-$(DATE)$(REVISION)
AUTHOR=KAWAMATA, Yoshihiro <kaw@on.rim.or.jp>

CDR_DEV=cd1

USB_DEV=svnd1
USB_MNT=/mnt
USB_IMG=media.img

all:
	@echo /$(FI_FILENAME)/ - lets go

open-all: open-rdroot open-media open-fuguita

close-all: close-fuguita close-media close-rdroot

open-rdroot:
	-vnconfig svnd0 rdroot.img
	-mount /dev/svnd0a rdroot

close-rdroot:
	-umount rdroot
	-vnconfig -u svnd0

open-media:
	-vnconfig svnd1 media.img
	-mount /dev/svnd1a media

close-media:
	-umount media
	-vnconfig -u svnd1

open-fuguita:
	-vnconfig svnd2 media/fuguita.ffsimg
	-mount /dev/svnd2a fuguita

close-fuguita:
	-umount fuguita
	-vnconfig -u svnd2

iso:
	make open-fuguita
	echo "$(VERSION)-$(DATE)$$(($(REVISION)+1))" > fuguita/usr/fuguita/version
	make close-fuguita

	/usr/local/bin/mkisofs \
		-no-iso-translate \
		-R \
		-allow-leading-dots \
		-l -d -D -N -v \
		-V "$(PROJNAME)-$(VERSION)-$(DATE)$$(($(REVISION)+1))" \
		-A "$(PROJNAME)-$(VERSION)-$(DATE)$$(($(REVISION)+1))" \
		-p "$(AUTHOR)" \
		-publisher "$(AUTHOR)" \
		-b cdbr -no-emul-boot \
		-c boot.catalog \
		-o /opt/fi/4.7/livecd.iso \
		/opt/fi/4.7/media/ \
	&& echo $$(($(REVISION)+1)) > revcount_cdmaster

hyb:
	make open-fuguita
	echo "$(VERSION)-$(DATE)$$(($(REVISION)+1))" > fuguita/usr/fuguita/version
	make close-fuguita

	mkhybrid -a -R -L -l -d -D -N \
		-o /opt/fi/4.7/livecd.iso \
		-v -v \
		-A "FuguIta - OpenBSD LiveCD" \
		-P "Copyright (c) `date +%Y` KAWAMATA Yoshihiro" \
		-p "KAWAMATA Yoshihiro, http://kaw.ath.cx/openbsd/?en/LiveCD" \
		-V "$(PROJNAME)-$(VERSION)-$(DATE)$$(($(REVISION)+1))" \
		-b cdbr \
		-c boot.catalog \
		/opt/fi/4.7/media/ \
	&& echo $$(($(REVISION)+1)) > revcount_cdmaster

boot: bsd.rdcd bsd.mp.rdcd lib/cdbr lib/cdboot
	cp lib/cdbr lib/cdboot media/.
	[ -d media/etc ] || mkdir media/etc
	cp lib/boot.conf media/etc/.
	: '[ -d media/sbin ] || mkdir media/sbin'
	: 'cp -p /sbin/vnconfig media/sbin; strip media/sbin/vnconfig'
	: '/usr/mdec/installboot -v media/boot /usr/mdec/biosboot svnd1'

bsd.rdcd: bsd.orig rdroot.img
	cp bsd.orig bsd
	lib/rdsetroot bsd < rdroot.img
	gzip -c9 bsd > media/bsd-fi

bsd.mp.rdcd: bsd.mp.orig rdroot.img
	cp bsd.mp.orig bsd.mp
	lib/rdsetroot bsd.mp < rdroot.img
	gzip -c9 bsd.mp > media/bsd-fi.mp

cdemu:
	/usr/local/bin/qemu -m 256 -localtime -monitor stdio -cdrom livecd.iso -boot d

usbemu:
	/usr/local/bin/qemu -m 256 -localtime -monitor stdio -hda media.img c -boot c

gz: cdgz usbgz

cdgz:
	cp livecd.iso $(FI_FILENAME).iso
	gzip -v9 $(FI_FILENAME).iso

usbgz:
	gzip -cv9 media.img > $(FI_FILENAME).usbimg.gz

cdrburn: cdrclean cdburn

cdrclean:
	cdio -v -f /dev/r$(CDR_DEV)c blank

cdburn:
	cdio -v -f /dev/r$(CDR_DEV)c tao livecd.iso

clean:
	rm -f bsd bsd.mp livecd.iso $(FI_FILENAME).iso.gz $(FI_FILENAME).usbimg.gz

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
