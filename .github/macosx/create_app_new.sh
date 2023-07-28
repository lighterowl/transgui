#!/bin/sh

set -xe

prog_ver=$(xmllint --xpath 'string(//StringTable/@ProductVersion)' ../../transgui.lpi)
exename=../../units/transgui
appname="Transmission Remote GUI"
dmg_dist_file="../../Release/transgui.dmg"
dmgfolder=./Release
appfolder="$dmgfolder/$appname.app"

mkdir -p ../../Release/

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
