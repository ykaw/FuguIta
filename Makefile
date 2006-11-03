# Copyright (c) 2006, Yoshihiro Kawamata
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

FI_FILENAME=FuguIta-4.0-200611011
CDR_DEV=cd1

all:
	@echo lets go

cdrclean:
	cdrecord -v dev=/dev/r$(CDR_DEV)c blank=fast

cdrburn: cdrclean cdburn

cdburn: livecd.iso
	cdrecord -v dev=/dev/r$(CDR_DEV)c livecd.iso

bgz: livecd.iso
	bzip2 -cv9 livecd.iso > $(FI_FILENAME).iso.bz2
	gzip -cv9 livecd.iso > $(FI_FILENAME).iso.gz

livecd.iso: tree
	cd cdroot.dist && mkhybrid -a -R -L -l -d -v -o ../livecd.iso -b cdbr -c boot.catalog .

tree: bsd.rdcd lib/cdbr lib/cdboot
	cp lib/cdbr lib/cdboot cdroot.dist
	cp bsd.rdcd cdroot.dist/bsd
	echo 'set image /bsd' > cdroot.dist/etc/boot.conf

bsd.rdcd: bsd.orig rdroot.dist.img
	cp bsd.orig bsd
	lib/rdsetroot bsd < rdroot.dist.img
	gzip -c9 bsd > bsd.rdcd

vnoff:
	umount /dev/svnd0a; vnconfig -u svnd0

vnon:
	vnconfig svnd0 rdroot.dist.img; mount /dev/svnd0a rdroot.dist

emu:
	qemu -m 256 -localtime -monitor stdio -cdrom livecd.iso -boot d

clean:
	rm -f livecd.iso
	>$(FI_FILENAME).iso.gz
	>$(FI_FILENAME).iso.bz2
