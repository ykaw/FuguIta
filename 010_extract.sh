#!/bin/sh

set -e
set -x

origwd=$(pwd)
[[ -z "$origwd" ]] && exit 1

ver=$(uname -r)
shortver=$(echo $ver|tr -dc 0-9)

rm -rf staging
mkdir staging

cd staging
tar xzpf ../install_sets/base${shortver}.tgz
tar xzpf ../install_sets/comp${shortver}.tgz
tar xzpf ../install_sets/game${shortver}.tgz
tar xzpf ../install_sets/man${shortver}.tgz
tar xzpf ../install_sets/xbase${shortver}.tgz
tar xzpf ../install_sets/xfont${shortver}.tgz
tar xzpf ../install_sets/xserv${shortver}.tgz
tar xzpf ../install_sets/xshare${shortver}.tgz
tar xzpf ./var/sysmerge/etc.tgz
tar xzpf ./var/sysmerge/xetc.tgz

cd $origwd
