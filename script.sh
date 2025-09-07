#!/bin/bash
printf "%s\n" "Script Begin"
#:<<'end'
packages="git bc  bison flex libssl-dev libc6-dev make libncurses5-dev libgnutls28-dev" 
#cross_compiler="crossbuild-essential-armhf" "crossbuild-essential-arm"
cross_compiler="crossbuild-essential-arm64"
#cross_compiler="crossbuild-essential-armhf"
target_file=build_env.sh
#sudo apt autoremove $packages -y

sleep 5
sudo apt install  $packages -y
sudo apt install  $cross_compiler -y
dt="--depth=1"
sudo git clone $dt https://github.com/raspberrypi/linux
sudo git clone  https://git.busybox.net/busybox/
sudo git clone  https://github.com/u-boot/u-boot.git/

cat << 'EOF' > $target_file
#!/bin/bash

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
#export ARCH=arm
#export CROSS_COMPILE=arm-linux-gnueabihf-

EOF

if [ -f $target_file  ]
then
	printf "%s\n" "file is available giving exeutable perm"
	chmod +x $target_file
else
	printf "%s\n" "file is not available"
fi

source $target_file
echo $ARCH
echo $CROSS_COMPILE

cd linux/
make bcm2711_defconfig
make menuconfig
make -j$(nproc)
#end
cd ../
cd u-boot
make rpi_arm64_defconfig
make menuconfig
make 
cd ../
dir="rootfs bootfs"
for m_dir in $dir
do
	if [ -d $m_dir ]
	then
		printf "%s\n" "$m_dir directory is available"
	else
		mkdir $m_dir
	fi
done
sub_dir="bin boot home tmp var etc mount sbin"
cd rootfs
for dir in $sub_dir
do
	if [ -d "$dir" ]
	then 
		printf "%s\n" "$dir dir is availble"
	else
		mkdir $dir
	fi
done
cd ../busybox
pwd
sleep 15
if [ -f busybox ] && [ -x busybox ]
then
	printf "%s\n" "busybox is available & executable"
else
	sudo make menuconfig
	sudo make
fi
cp busybox ../rootfs/bin/
pwd
cd ../rootfs/bin
pwd 
s_link="ls mkdir rmdir kill mount sh cp mv vim rm clear touch stat"
for link in $s_link
do
	if [ -f "$link" ]
	then
		printf "%s\n" "$link is  availbe"
	else
	ln -s busybox $link
	fi
done
pwd
cd ../sbin/
pwd
ln -s /bin/busybox init
cd ../../
pwd
cp linux/arch/arm64/boot/Image bootfs/
cd bootfs
if [ -d overlays ]
then
	printf "%s\n" "overlays is availble"
else
	mkdir overlays
fi
cd ../
cp linux/arch/arm64/boot/dts/overlays/mini* bootfs/overlays/
cp linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb bootfs/
cd rootfs/etc/
if [ -d init.d ]
then
	printf "%s\n" "init.d is availbe"
else
	mkdir init.d
fi
file=inittab
cat << 'end' >> $file
#/etc/inittab
# Run system initialzation script
::sysinit:/etc/init.d/rcs
# Start an interactive shell on serial console
ttyAMA0::respawn:/bin/sh
end
printf "%s\n" "script End"
