#!/bin/sh
for f in `find * -type f -name '*.[0-9]' -print`
do
    if [ `wc -l < $f` -eq 1 ] && grep -q '^\.so ' $f
    then
        set -- `cat $f`
        echo "rm $f && ln -s ${2##*/} $f"
    fi
done
