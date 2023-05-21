#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.3"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.3"

fixup_fpc_cfg() {
  local fpc_cfg_path=$1
  shift

  echo '-Fl/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib' >> "$fpc_cfg_path"
  echo '-k-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks' >> "$fpc_cfg_path"
}

make_fpc_cfg() {
  fpcmkcfg -d basepath=${fpc_basepath} -o ~/.fpc.cfg
  fixup_fpc_cfg ~/.fpc.cfg
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
  export PATH=${fpc_installdir}/bin:${fpc_basepath}:$PATH

  make_fpc_cfg

  cd "$sdk_dir"
  curl -L -o lazarus-src.tar.gz 'https://gitlab.com/dkk089/lazarus/-/archive/transgui/lazarus-transgui.tar.gz'
  tar xf lazarus-src.tar.gz
  cd lazarus
  make bigide
  export PATH=$PWD:$PATH
}

brew install openssl@3

if [[ -d $sdk_dir ]]; then
  export PATH=${sdk_dir}/lazarus:${fpc_installdir}/bin:${fpc_basepath}:$PATH
  make_fpc_cfg
else
  fpc_lazarus_build_install
fi

cd "$repo_dir"

build=$(git rev-list --abbrev-commit --max-count=1 HEAD)
sed -i.bak -e "s/@GIT_COMMIT@/$build/" buildinfo.pas

cd "${repo_dir}/.github/macosx"
source create_app_new.sh
