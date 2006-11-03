#====================
# partial loader in interim rc file
# for LiveCD
#
# KAWAMATA, Yoshihiro
# kaw@on.rim.or.jp
#====================


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
# KLUDGE: Re-lndir under /usr/local/lib/X11/fonts
#
if [ -h /mfs/usr/local/lib/X11/fonts ]; then
    rm /mfs/usr/local/lib/X11/fonts
    mkdir -p /mfs/usr/local/lib/X11/fonts
    (cd /mfs/usr/local/lib/X11/fonts && lndir -s /cdrom/usr/local/lib/X11/fonts)
fi

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

#-------------------------------------------
# set time stamp of dirs containing font files
# (to avoid re-build font caches)
#
(cd /mfs && for d in usr/*/lib/X11/fonts/*; do touch -cm -r /cdrom/$d $d; done)
