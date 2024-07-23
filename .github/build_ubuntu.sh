#!/usr/bin/env bash

set -xe

readonly repo_dir=$PWD
readonly sdk_dir=~/.transgui_sdk
readonly fpc_installdir="${sdk_dir}/fpc-3.2.4-rc1"
readonly fpc_basepath="${fpc_installdir}/lib/fpc/3.2.4"

fpc_lazarus_build_install() {
  sudo apt install -yqq --no-install-recommends fpc build-essential

  fpcmkcfg -d basepath=/usr/lib/x86_64-linux-gnu/fpc/3.2.2 -o ~/.fpc.cfg

  mkdir -p "$sdk_dir"
  cd "$sdk_dir"
  readonly fpc324_rc1_commit='d78e2897014a69f56a1cfb53c75335c4cc37ba0e'
  curl -L -o fpc-src.tar.bz2 "https://gitlab.com/freepascal.org/fpc/source/-/archive/${fpc324_rc1_commit}/source-${fpc324_rc1_commit}.tar.bz2"
  tar xf fpc-src.tar.bz2
  mv "source-${fpc324_rc1_commit}" fpc-src
  cd fpc-src

  make all
  mkdir -p "${fpc_installdir}"
  make PREFIX=$fpc_installdir install
  export PATH=${fpc_installdir}/bin:${fpc_basepath}:$PATH
  fpcmkcfg -d basepath=${fpc_basepath} -o ~/.fpc.cfg

  cd "$sdk_dir"
  local -r lazarus_commit='4e69368d79e3801ad26a7bc7c1eda0ad3cf7dcc4'
  curl -L -o lazarus-src.tar.bz2 "https://gitlab.com/dkk089/lazarus/-/archive/${lazarus_commit}/lazarus-${lazarus_commit}.tar.bz2"
  tar xf lazarus-src.tar.bz2
  mv "lazarus-${lazarus_commit}" lazarus
  cd lazarus
  make bigide LCL_PLATFORM=qt5
  export PATH=$PWD:$PATH
}

sudo apt update -yqq
sudo apt install -yqq build-essential libfuse2 qtbase5-dev-tools qt5-qmake libxml2-utils

curl -L -O https://github.com/davidbannon/libqt5pas/releases/download/v1.2.15/libqt5pas1_2.15-1_amd64.deb
curl -L -O https://github.com/davidbannon/libqt5pas/releases/download/v1.2.15/libqt5pas-dev_2.15-1_amd64.deb
sudo apt install libqt5pas1_2.15-1_amd64.deb libqt5pas-dev_2.15-1_amd64.deb

if [[ -d $sdk_dir ]]; then
  export PATH=${sdk_dir}/lazarus:${fpc_installdir}/bin:${fpc_basepath}:$PATH
  fpcmkcfg -d basepath=${fpc_basepath} -o ~/.fpc.cfg
else
  fpc_lazarus_build_install
  cd "$repo_dir"
fi

build=$(git rev-list --abbrev-commit --max-count=1 HEAD)
sed -i "s/@GIT_COMMIT@/$build/" buildinfo.pas

pushd test
lazbuild transguitest.lpi --lazarusdir=${sdk_dir}/lazarus
./units/transguitest -a
popd

lazbuild transgui.lpi --ws=qt5 --build-mode=Release --lazarusdir=${sdk_dir}/lazarus
cd units

curl -L -O https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
curl -L -O https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
chmod +x linuxdeploy-plugin-qt-x86_64.AppImage

app_ver=$(xmllint --xpath 'string(//StringTable/@ProductVersion)' ../transgui.lpi)
VERSION=$app_ver ./linuxdeploy-x86_64.AppImage -e transgui --create-desktop-file \
  --appdir AppDir --output appimage -i ../transgui.png --plugin qt
sha256sum transgui-${app_ver}-x86_64.AppImage
mv transgui-${app_ver}-x86_64.AppImage transgui-x86_64.AppImage
