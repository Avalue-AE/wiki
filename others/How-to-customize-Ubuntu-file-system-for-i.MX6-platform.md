# How to customize Ubuntu file system for i.MX6 platform?

In this tutorial we will show you the way to modify Ubuntu file system for i.MX6 platform.

Target board : RSC-IMX61

1. Please refer to this link to install Ubuntu into eMMC and make a bootable SD card with Ubuntu inside.
2. Boot RSC-IMX61 from SD card.
3. Mount eMMC partition(/dev/mmcblk0p1) to one of the folder. For example :  
```
#mount /dev/mmcblk0p1 /media
```
4. Follow procedure below to switch to eMMC partition.

```
#chroot /media
```

5. Now you are in eMMC partition right now and you can make any modification for it. For example, you can install or uninstall library by command “apt-get”
6. Once you finish modification for the rootfs on eMMC, you will have to use command “exit” to change back to SD card.
7. Use command below to compress whole rootfs on eMMC into tar.bz2 file.

```
#cd /media
#sudo tar jcvfp ../ubuntu.tar.bz2 ./
```

Copy ubuntu.tar.bz2 to \mfgtool\Image\Filesystem of mfgtool and flash it to eMMC.