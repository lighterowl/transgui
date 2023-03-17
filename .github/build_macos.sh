#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.3"

fixup_fpc_cfg() {
  local fpc_cfg_path=$1
  shift

  echo '-Fl/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib' >> "$fpc_cfg_path"
  echo '-k-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks' >> "$fpc_cfg_path"
}

fpc_lazarus_build_install() {
  brew install fpc
  cp /usr/local/etc/fpc.cfg ~/.fpc.cfg
  fixup_fpc_cfg ~/.fpc.cfg

  mkdir -p "$sdk_dir"
  cd "$sdk_dir"
  readonly fpc323_commit='0c5256300a323c78caa0b1a9cb772ac137f5aa8e'
  curl -O "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc323_commit}/source-${fpc323_commit}.tar.gz"
  tar xf "source-${fpc323_commit}.tar.gz"
  cd "source-${fpc323_commit}"

  make \
    COMPILER_LIBRARYDIR='/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib' \
    COMPILER_OPTIONS=-k-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks \
    all
  mkdir -p "${fpc_installdir}"
  make PREFIX=${fpc_installdir} install
  export PATH=${fpc_installdir}/bin:${fpc_installdir}/lib/fpc/3.2.3:$PATH

  fpcmkcfg -d basepath=${fpc_installdir}/lib/fpc/3.2.3 -p \
    -o "${fpc_installdir}/etc/fpc.cfg"
  fixup_fpc_cfg "${fpc_installdir}/etc/fpc.cfg"
  mkdir -p "${fpc_installdir}/lib/fpc/etc"
  ln -s ../../../etc/fpc.cfg "${fpc_installdir}/lib/fpc/etc/fpc.cfg"

  cd "$sdk_dir"
  curl -L -o lazarus-src.tar.gz 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.6/lazarus-2.2.6-0.tar.gz/download'
  tar xf lazarus-src.tar.gz
  cd lazarus
  make bigide
  export PATH=$PWD:$PATH
}

brew install openssl@3

if [[ -d $sdk_dir ]]; then
  export PATH=${sdk_dir}/lazarus:${fpc_installdir}/bin:${fpc_installdir}/lib/fpc/3.2.3:$PATH
else
  fpc_lazarus_build_install
fi

cd "${repo_dir}/.github/macosx"
source create_app_new.sh
