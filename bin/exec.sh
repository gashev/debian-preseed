#!/usr/bin/env bash

set -e
set -x

if [ $# != 2 ] ; then
    NAME=${0##*/}
    echo "Using: $NAME ISO ISO"
    exit
fi

ISO="${1}"
OUTPUT="${2}"
APP_FOLDER=$(readlink -f "$(dirname $0)/../")
TEMP_FOLDER="$(mktemp -d)"
MOUNT_FOLDER="$TEMP_FOLDER/loopdir/"
INITRD_EXTRACT_FOLDER="$TEMP_FOLDER/initrd/"

mkdir "$MOUNT_FOLDER"
sudo mount -o loop "$ISO" "$MOUNT_FOLDER"
mkdir "$TEMP_FOLDER/cd"
rsync -a -H --exclude=TRANS.TBL "$MOUNT_FOLDER" "$TEMP_FOLDER/cd"
sudo umount "$MOUNT_FOLDER"
mkdir "$INITRD_EXTRACT_FOLDER"
cd "$INITRD_EXTRACT_FOLDER"
gzip -d < "$TEMP_FOLDER/cd/install.amd/initrd.gz" | sudo cpio --extract --verbose --make-directories --no-absolute-filenames 

cp "$APP_FOLDER/conf/preseed.cfg" "$INITRD_EXTRACT_FOLDER/preseed.cfg"
chmod +w "$TEMP_FOLDER/cd/install.amd/initrd.gz"
find . | sudo cpio -H newc --create --verbose | gzip -9 > "$TEMP_FOLDER/cd/install.amd/initrd.gz"

chmod +w "$TEMP_FOLDER/cd/isolinux/isolinux.cfg"
cp -f "$APP_FOLDER/conf/isolinux.cfg" "$TEMP_FOLDER/cd/isolinux/"
cd "$TEMP_FOLDER/cd"
chmod +w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt
chmod u+w "$TEMP_FOLDER/cd/isolinux/isolinux.bin"
genisoimage -o "$OUTPUT" -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat "$TEMP_FOLDER/cd"

sudo /bin/chown -R $(whoami): "$TEMP_FOLDER"
chmod -R +w "$TEMP_FOLDER"
rm -rf "$TEMP_FOLDER"

