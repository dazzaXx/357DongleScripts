#!/bin/bash

# TNTGD2 - Taiko no Tatsujin Green Version Dongle 2

set -euo pipefail

USBIMG="/TNTGD2/TNTGD2_USB.img"
SHLOG="/TNTGD2/TNTGD2.log"
LIBCOMPOSITE="/etc/modules-load.d/libcomposite.conf"
BOOTCONFIG="/boot/config.txt"
DATABIN="0000001673657269616C697A6174696F6E3A3A61726368697665000A040404080000000100000000000000000B00201903"
BINLOCATION="/TNTGD2/USBMNT/VERSIONUP/DATA00000.BIN"
USBMNT="/TNTGD2/USBMNT/"
SERVICE="/etc/systemd/system/TNTGD2.service"
timestamp=$(date)

if [ -f "$SHLOG" ]; then # Check if the log exists, if it does then delete it and print the log header.
	rm /TNTGD2/TNTGD2.log
	echo "Taiko no Tatsujin Green Version Dongle 2 LOG" > "$SHLOG"
	echo -e "-------------------------------------------------\n" >> "$SHLOG"
fi

if [ ! -f "$SERVICE" ]; then # Check if the TNTGD2 service doesnt exist, if not, create it.
	echo -e "\n[$timestamp] Creating Service file for autobooting." >> "$SHLOG"
	echo -e "[Unit]\nDescription=TNTGD2 - Taiko no Tatsujin Green Version Dongle 2 Emulator\n\n[Service]\nExecStart=/TNTGD2/TNTGD2.sh\n\n[Install]\nWantedBy=multi-user.target" > "$SERVICE"
	systemctl enable TNTGD2 # Enable the service and start it.
	systemctl start TNTGD2
else
	echo "[$timestamp] Service already exists, skipping." >> "$SHLOG"
fi

if ! grep -q "\[all\]" "$BOOTCONFIG"; then # Check the systems boot config for the [all] tag, if it doesnt exist, append it to the end after a newline.
	echo "[$timestamp] [all] not found in boot config, adding now." >> "$SHLOG"
	echo -e "\n[all]" >> "$BOOTCONFIG"
else
	echo -e "\n[$timestamp] [all] tag was found in boot config, skipping." >> "$SHLOG"
fi

if ! grep -q "dtoverlay=dwc2,dr_mode=peripheral" "$BOOTCONFIG"; then # Similar as above, check to see if DWC2 is added with dr_mode, if not, add it under the [all] tag.
	echo "[$timestamp] dtoverlay not found in boot config, adding now." >> "$SHLOG"
	echo "dtoverlay=dwc2,dr_mode=peripheral" >> "$BOOTCONFIG"
else
	echo "[$timestamp] dtoverlay is already in boot config, skipping." >> "$SHLOG"
fi

if [ ! -f "$LIBCOMPOSITE" ]; then # Check to see if libcomposite has a .conf file in modules-load.d , if not, create the file and print the module name within itself.
	echo "[$timestamp] libcomposite module not loaded, creating .conf file now and rebooting." >> "$SHLOG"
	echo "libcomposite" > "$LIBCOMPOSITE"
	reboot # To apply all changes so far up to here.
else
	echo "[$timestamp] libcomposite is already present, skipping." >> "$SHLOG" 
fi

if [ ! -f "$USBIMG" ]; then # Check if the emulated USB's storage image exists, if not, create a 265MB .IMG and format it to FAT32.
	echo "[$timestamp] Taiko no Tatsujin Green Version Dongle 2 USB Image DOES NOT exist, creating blank image." >> "$SHLOG"
	dd if=/dev/zero of=/TNTGD2/TNTGD2_USB.img bs=1M count=265
	echo "[$timestamp] Blank Image Generated." >> "$SHLOG"
	mkdosfs -F 32 /TNTGD2/TNTGD2_USB.img
	echo "[$timestamp] Blank Image formatted to FAT32." >> "$SHLOG"
else
	echo "[$timestamp] Taiko no Tatsujin Green Version Dongle 2 USB Image already exists, skipping." >> "$SHLOG"
fi

cd /TNTGD2
mkdir -p USBMNT
echo "[$timestamp] Mounting USB .img to check contents." >> "$SHLOG"
mount -o rw "$USBIMG" "USBMNT"

if [ ! -f "$BINLOCATION" ]; then # Once the .img has been mounted, scan the root of it to see if DATA00000.BIN exists, if not, build the binary file on it.
	mkdir /TNTGD2/USBMNT/VERSIONUP
	cd /TNTGD2/USBMNT/VERSIONUP
	echo "[$timestamp] DATA00000.BIN not found on the USB drive, building binary file and copying over now." >> "$SHLOG"
	printf "%s" "$DATABIN" | perl -pe 's/([0-9A-Fa-f]{2})/chr(hex($1))/eg' > "$BINLOCATION"
	cd /TNTGD2
else
	echo "[$timestamp] DATA00000.BIN is already on the USB drive, skipping." >> "$SHLOG"
fi

echo "[$timestamp] Syncing Changes to USB drive, if any." >> "$SHLOG"
sync
echo "[$timestamp] Unmounting USB .img now." >> "$SHLOG"
umount "$USBMNT" # Sync changes if any has been made and unmount the .img before it's properly mounted as a USB drive.

echo "[$timestamp] Setting up USB drive now! If there is an error past this point, or the USB is already active, the log will stop here." >> "$SHLOG"

mkdir -p /sys/kernel/config/usb_gadget/TNTG_Dongle_2
cd /sys/kernel/config/usb_gadget/TNTG_Dongle_2
echo 0x0b9a > idVendor
echo 0x0c00 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB
mkdir -p strings/0x409
echo "268411060021" > strings/0x409/serialnumber
echo "dazzaXx" > strings/0x409/manufacturer
echo "Taiko no Tatsujin Green Version Dongle 2" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: Mass Storage" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
mkdir -p functions/mass_storage.usb0
echo 0 > functions/mass_storage.usb0/lun.0/cdrom
echo 0 > functions/mass_storage.usb0/lun.0/ro
echo /TNTGD2/TNTGD2_USB.img > functions/mass_storage.usb0/lun.0/file
ln -s functions/mass_storage.usb0 configs/c.1/
ls /sys/class/udc > UDC

echo "[$timestamp] USB drive should be mounted and security files already copied to the USB drive, have a nice day!" >> "$SHLOG"
