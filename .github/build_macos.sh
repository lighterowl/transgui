#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.4-rc1"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.4"
readonly brew_prefix=$(brew --prefix)
readonly macosx_libdir=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
readonly macosx_frameworkdir=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks
[[ $1 == cross ]] && readonly cross_build=1

fixup_fpc_cfg() {
  local fpc_cfg_path=$1
  shift

  echo "-Fl${macosx_libdir}" >> "$fpc_cfg_path"
  echo "-k-F${macosx_frameworkdir}" >> "$fpc_cfg_path"
  echo "-k-weak_framework UserNotifications" >> "$fpc_cfg_path"
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

  # use a private fork which includes a fix for compilation under Sequoia
  readonly fpc324_rc1_commit='dae96b96a1839e1a3624c664d6293661cc4bed67'
  curl -L -o fpc-src.tar.bz2 "https://gitlab.com/dkk089/fpc-src/-/archive/${fpc324_rc1_commit}/fpc-src-${fpc324_rc1_commit}.tar.bz2"
  tar xf fpc-src.tar.bz2
  mv "fpc-src-${fpc324_rc1_commit}" fpc-src
  cd fpc-src

  mkdir -p "${fpc_installdir}"

  local -r make_opts_native=(
    COMPILER_LIBRARYDIR=${macosx_libdir}
    COMPILER_OPTIONS=-k-F${macosx_frameworkdir}
  )
  make "${make_opts_native[@]}" all
  make PREFIX=${fpc_installdir} install

  if [[ $(uname -m) != arm64 ]]; then
    local -r make_opts_cross=("${make_opts_native[@]}" CPU_SOURCE=x86_64 CPU_TARGET=aarch64)
    make "${make_opts_cross[@]}" all
    make PREFIX=${fpc_installdir} "${make_opts_cross[@]}" crossinstall
  fi

  export PATH=${fpc_installdir}/bin:${fpc_basepath}:$PATH

  make_fpc_cfg

  cd "$sdk_dir"
  local -r lazarus_commit='dab5c509c6fd70f8fac2144e468291899286616f'
  curl -L -o lazarus-src.tar.bz2 "https://gitlab.com/dkk089/lazarus/-/archive/${lazarus_commit}/lazarus-${lazarus_commit}.tar.bz2"
  tar xf lazarus-src.tar.bz2
  mv "lazarus-${lazarus_commit}" lazarus
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
  lazbuild "--compiler=${fpc_basepath}/${compiler}" \
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
