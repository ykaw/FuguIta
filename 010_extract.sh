#!/bin/sh

set -e
set -x

origwd=$(pwd)
[[ -z "$origwd" ]] && exit 1

rm -rf staging
mkdir staging

cd staging
tar xzpf ../install_sets/base70.tgz
tar xzpf ../install_sets/comp70.tgz
tar xzpf ../install_sets/game70.tgz
tar xzpf ../install_sets/man70.tgz
tar xzpf ../install_sets/xbase70.tgz
tar xzpf ../install_sets/xfont70.tgz
tar xzpf ../install_sets/xserv70.tgz
tar xzpf ../install_sets/xshare70.tgz
tar xzpf ./var/sysmerge/etc.tgz
tar xzpf ./var/sysmerge/xetc.tgz

cd $origwd
