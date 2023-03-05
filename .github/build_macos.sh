#!/usr/bin/env bash

set -e
repo_dir=$PWD

fixup_fpc_cfg() {
  local fpc_cfg_path=$1
  shift

  echo '-Fl/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib' >> "$fpc_cfg_path"
  echo '-k-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks' >> "$fpc_cfg_path"
}

brew install fpc
cp /usr/local/etc/fpc.cfg ~/.fpc.cfg
fixup_fpc_cfg ~/.fpc.cfg

readonly fpc323_commit='0c5256300a323c78caa0b1a9cb772ac137f5aa8e'
curl -O "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc323_commit}/source-${fpc323_commit}.zip"
unzip "source-${fpc323_commit}.zip"
cd "source-${fpc323_commit}"

make \
  COMPILER_LIBRARYDIR='/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib' \
  COMPILER_OPTIONS=-k-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks \
  all
mkdir -p ~/fpc-3.2.3
make PREFIX=~/fpc-3.2.3 install
export PATH=~/fpc-3.2.3/bin:~/fpc-3.2.3/lib/fpc/3.2.3:$PATH

fpcmkcfg -d basepath=${HOME}/fpc-3.2.3/lib/fpc/3.2.3 -o ~/.fpc.cfg
fixup_fpc_cfg ~/.fpc.cfg

cd
curl -L -o lazarus-src.zip 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.4/lazarus-2.2.4-0.zip/download'
unzip lazarus-src.zip
cd lazarus
make bigide
export PATH=$PWD:$PATH

cd "$repo_dir"
lazbuild transgui.lpi --lazarusdir=${HOME}/lazarus
