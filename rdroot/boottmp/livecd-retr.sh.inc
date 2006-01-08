#-------------------------------------
# copy CD-ROM contents to rw-able mfs
#
echo -n "Copying files from CD-ROM to mfs ... "
cd /mfs
(cd ../cdrom && tar cf - etc home tmp root var) | tar xpf -
echo "done"

#-----------------------
# symlink from / to mfs
#
cd /
rm -rf /tmp
mv /etc /bootetc
ln -sf mfs/* .
cp /boottmp/fstab /etc

#-------------------------------------------
# symlink rest of contents from / to CD-ROM
#
ln -s cdrom/* .     2>/dev/null
#ln -s cdrom/.??* . 2>/dev/null ; # Maybe not needed

#-------------------------------------------
# lndir from /mfs/usr to /cdrom/usr
#
echo -n "Linking files from mfs to CD-ROM ... "
mkdir /mfs/usr && cd /mfs/usr && lndir -s /cdrom/usr
echo "done"

#-------------------------------------------
# Then, copy again for trivial dirs
#
for d in \
    usr/libexec/auth \
    usr/local/lib/wnn
  do
  if [ -d /mfs/$d ]; then
      rm -rf /mfs/$d && cd `dirname /cdrom/$d` && pax -rwpe `basename $d` `dirname /mfs/$d`
  fi
done

#-----------------------
# Extract an archive
#
echo "Extracting files from floppy to mfs ... "
cd /mfs
tar xpvzf /mnt/livecd-config.tar.gz

#-----------------------
# symlink from / to mfs
#
cd /
rm -rf /tmp
mv /etc /bootetc
ln -sf mfs/* .
cp /boottmp/fstab /etc

#-------------------------------------------
# symlink rest of contents from / to CD-ROM
#
ln -s cdrom/* .     2>/dev/null
#ln -s cdrom/.??* . 2>/dev/null ; # Maybe not needed
