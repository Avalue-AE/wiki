# How to update Debian 8 kernel?

1. Install Debian 8 AMD64 Version
2. Install app need

```
#sudo apt-get install alsa pulseaudio
```

3. Open terminal,Extract driver_patch.tar.bz2  
![tar_driver_patch](../imagesFAQ/How-to-update-Debian-8-kernel/tar_driver_patch.png)  

4. Into driver_patch folder,update kernel

```
#cd driver_patch
#sudo dpkg -i *.deb
```
![update_kernal](../imagesFAQ/How-to-update-Debian-8-kernel/update_kernel.png)  

5. After install new kernel, reboot
6. Into driver_patch folder, update driver

```
#cd deiver_patch
#sudo ./install.sh
```

![install_kernal](../imagesFAQ/How-to-update-Debian-8-kernel/install_kernel.png)  

7. Reboot
8. Setting Audio Mixer

```
#cd driver_patch
#./bx11.sh
```
![update_new_kernal](../imagesFAQ/How-to-update-Debian-8-kernel/update_new_kernel.png)  