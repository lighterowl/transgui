#!/bin/sh

set -xe

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

prog_ver="$(cat ../../VERSION.txt)"
build="$(git rev-list --abbrev-commit --max-count=1 HEAD ../..)"
lazarus_ver="$(lazbuild -v)"
fpc_ver="$(fpc -i V | head -n 1)"
exename=../../units/transgui
appname="Transmission Remote GUI"
dmg_dist_file="../../Release/transgui-$prog_ver.dmg"
dmgfolder=./Release
appfolder="$dmgfolder/$appname.app"

mkdir -p ../../Release/
sed -i.bak "s/'Version %s'/'Version %s Build $build'#13#10'Compiled by: $fpc_ver, Lazarus v$lazarus_ver'/" ../../about.lfm

pushd ../..
lazbuild --compiler=${fpc_installdir}/lib/fpc/3.2.3/ppcx64 --build-mode=Release \
  --ws=cocoa --lazarusdir=${sdk_dir}/lazarus transgui.lpi
popd

if ! [ -e $exename ]; then
  echo "$exename does not exist"
  exit 1
fi
strip "$exename"

rm -rf "$appfolder"

echo "Creating $appfolder..."
mkdir -p "$appfolder/Contents/MacOS/lang"
mkdir -p "$appfolder/Contents/Resources"

install_name_tool -add_rpath '@executable_path' "$exename"
mv "$exename" "$appfolder/Contents/MacOS"
package_openssl "$appfolder/Contents/MacOS"

cp ../../lang/transgui.* "$appfolder/Contents/MacOS/lang"
cp ../../history.txt "$dmgfolder"
cp ../../README.md "$dmgfolder"

cp PkgInfo "$appfolder/Contents"
cp transgui.icns "$appfolder/Contents/Resources"
sed -e "s/@prog_ver@/$prog_ver/" Info.plist > "$appfolder/Contents/Info.plist"

hdiutil create -ov -anyowners -volname "transgui-v$prog_ver" -format UDRW -srcfolder ./Release -fs HFS+ "tmp.dmg"

mount_device="$(hdiutil attach -readwrite -noautoopen "tmp.dmg" | awk 'NR==1{print$1}')"
mount_volume="$(mount | grep "$mount_device" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')"
cp transgui.icns "$mount_volume/.VolumeIcon.icns"
SetFile -c icnC "$mount_volume/.VolumeIcon.icns"
SetFile -a C "$mount_volume"

hdiutil detach "$mount_device"
rm -f "$dmg_dist_file"
hdiutil convert tmp.dmg -format UDBZ -imagekey zlib-level=9 -o "$dmg_dist_file"

rm tmp.dmg
rm -rf "$dmgfolder"
mv ../../about.lfm.bak ../../about.lfm
