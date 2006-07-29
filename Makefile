all:
	@echo lets go

cdrclean:
	cdrecord -v dev=/dev/rcd0c blank=fast

cdrburn: cdrclean cdburn

cdburn: livecd.iso
	cdrecord -v dev=/dev/rcd0c livecd.iso

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
