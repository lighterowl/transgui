#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.3"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.3"
readonly brew_prefix=$(brew --prefix)

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
  cp "${brew_prefix}/etc/fpc.cfg" ~/.fpc.cfg
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
  mv lazarus-transgui lazarus
  cd lazarus
  make bigide
  export PATH=$PWD:$PATH
}

package_openssl() {
  local bindir=$1
  local libcrypto
  local libssl

  set +x
  for i in $(brew ls openssl@3); do
    if [[ $i =~ libcrypto\.3\.dylib$ ]]; then
      libcrypto=$i
    elif [[ $i =~ libssl\.3\.dylib$ ]]; then
      libssl=$i
    fi
  done
  set -x

  if [[ -z $libcrypto || -z $libssl ]]; then
    echo >&2 "libcrypto = '${libcrypto}' , libssl = '${libssl}' - quitting"
    exit 1
  fi

  local libs=("$libcrypto" "$libssl")
  for lib in "${libs[@]}"; do
    local libname=${lib##*/}
    cp "$lib" "$bindir"
    install_name_tool -id "$libname" "${bindir}/${libname}"
  done

  install_name_tool -change "$libcrypto" '@executable_path/libcrypto.3.dylib' "${bindir}/libssl.3.dylib"
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

if [[ $(uname -m) == arm64 ]]; then
  compiler=ppca64
else
  compiler=ppcx64
fi

lazbuild --compiler=${fpc_installdir}/lib/fpc/3.2.3/${compiler} --build-mode=Release \
  --ws=cocoa --lazarusdir=${sdk_dir}/lazarus transgui.lpi

mkdir transgui_$compiler
cd transgui_$compiler

cp ../units/transgui .
strip transgui
install_name_tool -add_rpath '@executable_path' transgui
package_openssl "$PWD"
if [[ $compiler == ppca64 ]]; then
  for i in transgui *.dylib; do
    codesign --force -s - "$i"
  done
fi
