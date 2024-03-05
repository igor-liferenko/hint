#!/bin/bash -x

# NOTE: we may use online image builder instead of this script

IMG=openwrt-imagebuilder-19.07.0-rc1-ar71xx-generic.Linux-x86_64
URL=https://downloads.openwrt.org/releases/19.07.0-rc1/targets/ar71xx/generic
mkdir -p ~/openwrt
cd ~/openwrt
[ -e $IMG.tar.xz ] || wget $URL/$IMG.tar.xz || exit
rm -fr h/
mkdir h/
cd h/
tar -Jxf ../$IMG.tar.xz
cd $IMG/
mkdir -p files/etc/
cat <<'EOF' >files/etc/rc.local
mount /dev/sda1 /mnt
cat <<'FOE' | sh &
sleep 60 # adjust empirically that all output to ttyATH0 stops
stty -F /dev/ttyATH0 57600
printf +++ >/dev/ttyATH0
head -c 50 /mnt/data.txt | head -n 1 | sed 's/\r//' | awk 1 >/dev/ttyATH0 # DATA_SIZE
poweroff
FOE
exit 0
EOF

make image PROFILE=gl-inet-6416A-v1 PACKAGES="kmod-usb-storage kmod-fs-vfat coreutils-stty" FILES=files/
{ RET=$?; } 2>/dev/null
{ set +x; } 2>/dev/null
if [ $RET = 0 ]; then
  ls ~/openwrt/h/*/bin/*/*/*/*-squashfs-sysupgrade.bin # mtd -r write /tmp/fw.img firmware
  ls ~/openwrt/h/*/bin/*/*/*/*-squashfs-factory.bin # see below
fi

# Connect your computer to the LAN or WAN port using internet cable. Leave
# the other port unconnected.
# 
# While pressing the RESET button, power on the device. You will see the
# GREEN LED flashing.
# 
# Hold the RESET button until the GREEN LED flash 5 times, the RED LED
# will light up. Release your finger now.
# 
# Visit http://192.168.1.1 using your browser, you will see the following
# web interface.
# 
# Click ``Choose File'', choose the image file, then click ``Upload'', and
# then wait unit your new system boot up.
