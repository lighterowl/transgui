#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.3"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.3"

fpc_lazarus_build_install() {
  sudo apt install -yqq --no-install-recommends fpc build-essential

  fpcmkcfg -d basepath=/usr/lib/x86_64-linux-gnu/fpc/3.2.2 -o ~/.fpc.cfg

  mkdir -p "$sdk_dir"
  cd "$sdk_dir"
  readonly fpc323_commit='0c5256300a323c78caa0b1a9cb772ac137f5aa8e'
  curl -O "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc323_commit}/source-${fpc323_commit}.tar.gz"
  tar xf "source-${fpc323_commit}.tar.gz"
  cd "source-${fpc323_commit}"

  make all
  mkdir -p "${fpc_installdir}"
  make PREFIX=$fpc_installdir install
  export PATH=${fpc_installdir}/bin:${fpc_basepath}:$PATH
  fpcmkcfg -d basepath=${fpc_basepath} -o ~/.fpc.cfg

  cd "$sdk_dir"
  curl -L -o lazarus-src.tar.gz 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Zip%20_%20GZip/Lazarus%202.2.6/lazarus-2.2.6-0.tar.gz/download'
  tar xf lazarus-src.tar.gz
  cd lazarus
  make bigide LCL_PLATFORM=qt5
  export PATH=$PWD:$PATH
}

sudo apt update -yqq
sudo apt install -yqq build-essential libqt5pas-dev libfuse2 qtbase5-dev-tools qt5-qmake

if [[ -d $sdk_dir ]]; then
  export PATH=${sdk_dir}/lazarus:${fpc_installdir}/bin:${fpc_basepath}:$PATH
  fpcmkcfg -d basepath=${fpc_basepath} -o ~/.fpc.cfg
else
  fpc_lazarus_build_install
  cd "$repo_dir"
fi

lazbuild transgui.lpi --ws=qt5 --build-mode=Release --lazarusdir=${sdk_dir}/lazarus
cd units

curl -L -O https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
curl -L -O https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
chmod +x linuxdeploy-plugin-qt-x86_64.AppImage

app_ver=$(cat ../VERSION.txt)
VERSION=$app_ver ./linuxdeploy-x86_64.AppImage -e transgui --create-desktop-file \
  --appdir AppDir --output appimage -i ../transgui.png --plugin qt
sha256sum transgui-${app_ver}-x86_64.AppImage
