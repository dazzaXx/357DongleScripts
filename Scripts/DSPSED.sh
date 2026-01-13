#!/bin/bash

# DSPSED - Deadstorm Pirate Special Editon Security Dongle Emulator, made by dazzaXx.

set -euo pipefail

USBIMG="/DSPSED/DSPSED_USB.img"
SHLOG="/DSPSED/DSPSED.log"
LIBCOMPOSITE="/etc/modules-load.d/libcomposite.conf"
BOOTCONFIG="/boot/config.txt"
SERVICE="/etc/systemd/system/DSPSED.service"
timestamp=$(date)

if [ -f "$SHLOG" ]; then # Check if the log exists, if it does then delete it and print the log header.
	rm /DSPSED/DSPSED.log
	echo "Deadstorm Pirate Special Editon DONGLE EMULATOR LOG" > "$SHLOG"
	echo -e "-------------------------------------------------\n" >> "$SHLOG"
fi

if [ ! -f "$SERVICE" ]; then # Check if the T6BR service doesnt exist, if not, create it.
	echo -e "\n[$timestamp] Creating Service file for autobooting." >> "$SHLOG"
	echo -e "[Unit]\nDescription=DSPSED - Deadstorm Pirate Special Editon Dongle Emulator\n\n[Service]\nExecStart=/DSPSED/DSPSED.sh\n\n[Install]\nWantedBy=multi-user.target" > "$SERVICE"
	systemctl enable DSPSED # Enable the service and start it.
	systemctl start DSPSED
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
else
	echo "[$timestamp] libcomposite is already present, skipping." >> "$SHLOG" 
fi

if [ ! -f "$USBIMG" ]; then # Check if the emulated USB's storage image exists, if not, create a 265MB .IMG and format it to FAT32.
	echo "[$timestamp] Deadstorm Pirate Special Editon USB Image DOES NOT exist, creating blank image." >> "$SHLOG"
	dd if=/dev/zero of=/DSPSED/DSPSED_USB.img bs=1M count=265
	echo "[$timestamp] Blank Image Generated." >> "$SHLOG"
	mkdosfs -F 32 /DSPSED/DSPSED_USB.img
	echo "[$timestamp] Blank Image formatted to FAT32." >> "$SHLOG"
else
	echo "[$timestamp] Deadstorm Pirate Special Editon USB Image already exists, skipping." >> "$SHLOG"
fi

echo "[$timestamp] Setting up USB drive now! If there is an error past this point, or the USB is already active, the log will stop here." >> "$SHLOG"

mkdir -p /sys/kernel/config/usb_gadget/DSPSED_Dongle
cd /sys/kernel/config/usb_gadget/DSPSED_Dongle
echo 0x0b9a > idVendor
echo 0x0c00 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB
mkdir -p strings/0x409
echo "272311091018" > strings/0x409/serialnumber
echo "dazzaXx" > strings/0x409/manufacturer
echo "Deadstorm Pirate Special Editon Dongle Emulator" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: Mass Storage" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
mkdir -p functions/mass_storage.usb0
echo 0 > functions/mass_storage.usb0/lun.0/cdrom
echo 0 > functions/mass_storage.usb0/lun.0/ro
echo "$USBIMG" > functions/mass_storage.usb0/lun.0/file
ln -s functions/mass_storage.usb0 configs/c.1/
ls /sys/class/udc > UDC

echo "[$timestamp] USB drive should be mounted and security files already copied to the USB drive, have a nice day!" >> "$SHLOG"
