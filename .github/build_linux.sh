#!/usr/bin/env bash

set -xe

readonly build=$(git rev-list --abbrev-commit --max-count=1 HEAD)
sed -i "s/@GIT_COMMIT@/$build/" buildinfo.pas

pushd test
lazbuild transguitest.lpi "--lazarusdir=${TRANSGUI_LAZARUS_DIR}"
./units/transguitest -a
popd

lazbuild transgui.lpi --ws=qt5 --build-mode=Release "--lazarusdir=${TRANSGUI_LAZARUS_DIR}"
cd units

readonly app_ver=$(xmllint --xpath 'string(//StringTable/@ProductVersion)' ../transgui.lpi)
LINUXDEPLOY_OUTPUT_VERSION=$app_ver linuxdeploy-x86_64.AppImage \
  -e transgui --create-desktop-file --appdir AppDir \
  --output appimage -i ../transgui.png --plugin qt
sha256sum transgui-${app_ver}-x86_64.AppImage
mv transgui-${app_ver}-x86_64.AppImage transgui-x86_64.AppImage
