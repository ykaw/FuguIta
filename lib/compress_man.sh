#!/bin/sh

find . -type f -name '*.[0-9]' -links 1 -print | xargs gzip -v9

find . -type f -name '*.[0-9]' -links +1 -print |
while read f
do
    if file $f | grep -q 'gzip compressed data'
    then
        mv $f $f.gz
    else
        gzip -cv9 $f > $f.gz.tmp
        mv $f $f.gz
        cat $f.gz.tmp > $f.gz
        rm $f.gz.tmp
    fi
done

find . -type l -name '*.[0-9]' -print |
while read f
do
    ln -s `stat -f '%Y' $f`.gz $f.gz
    rm $f
done
