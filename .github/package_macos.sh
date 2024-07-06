#!/usr/bin/env bash

set -xe

readonly prog_ver=$(xmllint --xpath 'string(//StringTable/@ProductVersion)' transgui.lpi)
readonly appname="Transmission Remote GUI"
readonly dmgfolder=./Release
readonly macosx_dir='./.github/macosx'

readonly appfolder="${dmgfolder}/${appname}.app"

mkdir -p "$appfolder/Contents/MacOS/lang"
mkdir -p "$appfolder/Contents/Resources"

for i in libcrypto.3.dylib libssl.3.dylib transgui; do
  lipo -create -output "$appfolder/Contents/MacOS/$i" transgui_{ppca64,ppcx64}/"$i"
  chmod +x "$appfolder/Contents/MacOS/$i"
done

cp lang/transgui.* "$appfolder/Contents/MacOS/lang"
cp "${macosx_dir}/PkgInfo" "${appfolder}/Contents"
cp "${macosx_dir}/transgui.icns" "${appfolder}/Contents/Resources"
sed -e "s/@prog_ver@/$prog_ver/" "${macosx_dir}/Info.plist" > "${appfolder}/Contents/Info.plist"

hdiutil create -ov -anyowners -volname "transgui-v${prog_ver}" -format UDRW -srcfolder "$dmgfolder" -fs HFS+ tmp.dmg

mount_device=$(hdiutil attach -readwrite -noautoopen tmp.dmg | awk 'NR==1{print$1}')
mount_volume=$(mount | grep "$mount_device" | sed 's/^[^ ]* on //;s/ ([^)]*)$//')
cp "${macosx_dir}/transgui.icns" "$mount_volume/.VolumeIcon.icns"
SetFile -c icnC "$mount_volume/.VolumeIcon.icns"
SetFile -a C "$mount_volume"
hdiutil detach "$mount_device"

readonly dmg_dist_file="${dmgfolder}/transgui.dmg"
rm -f "$dmg_dist_file"
hdiutil convert tmp.dmg -format UDBZ -imagekey zlib-level=9 -o "$dmg_dist_file"
shasum -a 256 "$dmg_dist_file"
