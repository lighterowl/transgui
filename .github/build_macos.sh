#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.3"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.3"
readonly brew_prefix=$(brew --prefix)
readonly macosx_libdir=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
readonly macosx_frameworkdir=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks
[[ $1 == cross ]] && readonly cross_build=1

fixup_fpc_cfg() {
  local fpc_cfg_path=$1
  shift

  echo "-Fl${macosx_libdir}" >> "$fpc_cfg_path"
  echo "-k-F${macosx_frameworkdir}" >> "$fpc_cfg_path"
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

  mkdir -p "${fpc_installdir}"

  make_opts_native=(
    COMPILER_LIBRARYDIR=${macosx_libdir}
    COMPILER_OPTIONS=-k-F${macosx_frameworkdir}
  )
  make "${make_opts_native[@]}" all
  make PREFIX=${fpc_installdir} install

  make_opts_cross=("${make_opts_native[@]}" CPU_SOURCE=x86_64 CPU_TARGET=aarch64)
  make "${make_opts_cross[@]}" all
  make PREFIX=${fpc_installdir} "${make_opts_cross[@]}" crossinstall

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

  if [[ $cross_build ]]; then
    local openssl_tgz=$(brew fetch --arch arm --os big_sur openssl@3 | perl -n -e 'print $2 if(/^(Already downloaded|Downloaded to): (.*?\.tar\.gz)/);')
    local extract_dir=$(mktemp -d)
    tar -C "$extract_dir" -x -f "$openssl_tgz"
    cmd=find
    cmd_args=("$extract_dir" -name '*.dylib')
  else
    brew install openssl@3
    cmd=brew
    cmd_args=(ls openssl@3)
  fi

  set +x
  for i in $("$cmd" "${cmd_args[@]}"); do
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

my_lazbuild() {
  lazbuild --compiler=${fpc_installdir}/lib/fpc/3.2.3/${compiler} \
    --lazarusdir=${sdk_dir}/lazarus "$@"
}

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
  if [[ $cross_build ]]; then
    echo >&2 "Sorry, not supported"
    exit 1
  fi
  compiler=ppca64
elif [[ $cross_build ]]; then
  compiler=ppcrossa64
else
  compiler=ppcx64
fi

pushd test
my_lazbuild transguitest.lpi
./units/transguitest -a
popd

my_lazbuild --build-mode=Release --ws=cocoa transgui.lpi

mkdir transgui_$compiler
cd transgui_$compiler

cp ../units/transgui .
strip transgui
install_name_tool -add_rpath '@executable_path' transgui
package_openssl "$PWD"
if [[ $compiler == ppca64 || $compiler == ppcrossa64 ]]; then
  for i in transgui *.dylib; do
    codesign --force -s - "$i"
  done
fi
