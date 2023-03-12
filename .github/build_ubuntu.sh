#!/usr/bin/env bash

set -e
repo_dir=$PWD

apt update -yqq
apt install -yqq --no-install-recommends fpc build-essential

fpcmkcfg -d basepath=/usr/lib/x86_64-linux-gnu/fpc/3.2.2 -o ~/.fpc.cfg

readonly fpc323_commit='0c5256300a323c78caa0b1a9cb772ac137f5aa8e'
curl -O "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc323_commit}/source-${fpc323_commit}.tar.gz"
tar xf "source-${fpc323_commit}.tar.gz"
cd "source-${fpc323_commit}"

make all
mkdir -p ~/fpc-3.2.3
make PREFIX=~/fpc-3.2.3 install
export PATH=~/fpc-3.2.3/bin:~/fpc-3.2.3/lib/fpc/3.2.3:$PATH
fpcmkcfg -d basepath=${HOME}/fpc-3.2.3/lib/fpc/3.2.3 -o ~/.fpc.cfg

cd
curl -L -o lazarus-src.tar.gz 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.6/lazarus-2.2.6-0.tar.gz/download'
tar xf lazarus-src.tar.gz
cd lazarus
make bigide
export PATH=$PWD:$PATH

cd "$repo_dir"
lazbuild transgui.lpi --lazarusdir=${HOME}/lazarus
