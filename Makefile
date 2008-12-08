# Copyright (c) 2006, 2007, 2008, Yoshihiro Kawamata
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

PROJNAME=FuguIta
VERSION =4.4
DATE   !=date +%Y%m%d
REVISION=1

FI_FILENAME=$(PROJNAME)-$(VERSION)-$(DATE)$(REVISION)
AUTHOR=KAWAMATA, Yoshihiro <kaw@on.rim.or.jp>
CDR_DEV=cd1

all:
	@echo /$(FI_FILENAME)/ - lets go

usbbz:
	dd if=/dev/rsd0c bs=65536k | bzip2 -cv9 > $(FI_FILENAME).usbimg.bz2

usbkern: bsd.rdcd bsd.mp.rdcd
	mount /dev/sd0a /mnt
	cat bsd.rdcd > /mnt/bsd
	cat bsd.mp.rdcd > /mnt/bsd.mp
	umount /mnt

usbfill:
	mount /dev/sd0a /mnt
	-dd if=/dev/zero of=/mnt/tmp/fill bs=65536k
	rm -f /mnt/tmp/fill
	umount /mnt
	mount /dev/sd0d /mnt
	-dd if=/dev/zero of=/mnt/livecd-config/fill bs=65536k
	rm -f /mnt/livecd-config/fill
	umount /mnt

cdrburn: cdrclean cdburn

cdrclean:
	cdio -v -f /dev/r$(CDR_DEV)c blank

cdburn:
	cdio -v -f /dev/r$(CDR_DEV)c tao livecd.iso

bgz: bz gz

bz:
	bzip2 -cv9 livecd.iso > $(FI_FILENAME).iso.bz2

gz:
	gzip -cv9 livecd.iso > $(FI_FILENAME).iso.gz

livecd.iso: tree
	: 'cd cdroot.dist && mkhybrid -R -L -l -d -v -o ../livecd.iso -b cdbr -c boot.catalog .'
	: 'cd cdroot.dist && /usr/local/bin/mkisofs -R -L -l -d -v -o ../livecd.iso -b cdbr -no-emul-boot -c boot.catalog .'
	/usr/local/bin/mkisofs \
		-no-iso-translate \
		-R \
		-allow-leading-dots \
		-l -d -D -N -v \
		-V "$(FI_FILENAME)" \
		-A "$(FI_FILENAME)" \
		-p "$(AUTHOR)" \
		-publisher "$(AUTHOR)" \
		-b cdbr -no-emul-boot \
		-c boot.catalog \
		-o /opt/fuguita/4.4/livecd.iso \
		/opt/fuguita/4.4/cdroot.dist/

tree: bsd.rdcd bsd.mp.rdcd lib/cdbr lib/cdboot
	cp lib/cdbr lib/cdboot cdroot.dist
	cp bsd.rdcd cdroot.dist/bsd
	cp bsd.mp.rdcd cdroot.dist/bsd.mp
	echo 'set image /bsd' > cdroot.dist/etc/boot.conf

bsd.rdcd: bsd.orig rdroot.dist.img
	cp bsd.orig bsd
	lib/rdsetroot bsd < rdroot.dist.img
	gzip -c9 bsd > bsd.rdcd

bsd.mp.rdcd: bsd.mp.orig rdroot.dist.img
	cp bsd.mp.orig bsd.mp
	lib/rdsetroot bsd.mp < rdroot.dist.img
	gzip -c9 bsd.mp > bsd.mp.rdcd

vnoff:
	umount /dev/svnd0a; vnconfig -u svnd0

vnon:
	vnconfig svnd0 rdroot.dist.img; mount /dev/svnd0a rdroot.dist

emu:
	/usr/local/bin/qemu -m 256 -localtime -monitor stdio -cdrom livecd.iso -boot d

usbemu:
	/usr/local/bin/qemu -m 256 -localtime -monitor stdio -hda /dev/sd0c -boot c

clean:
	rm -f livecd.iso $(FI_FILENAME).iso.gz $(FI_FILENAME).iso.bz2
