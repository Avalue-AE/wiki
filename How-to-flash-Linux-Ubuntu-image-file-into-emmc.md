# How to flash Linux Ubuntu image file into emmc  

1. Get into BIOS and make sure you are using 64bit BIOS on Open Frame Tablet before staring.  

2. Please prepare a USB disk at least 16GB and format it in FAT32 format. Copy clonezilla image file to it.  

3. Decompress clonezilla image file to root directory of USB disk.  
![clonezilla_disk](clonezilla_disk.jpg)

4. Plug the USB disk to USB port of OFT-XXW01. Power on the system and press "F12" to get into Boot Manager of BIOS. Please select USB Disk as boot device to boot up the system.  
![oft_linux_2](oft_linux_2.jpg)

5. Please select the first option as below then press "enter".  
![oft_linux_3](oft_linux_3.jpg)

6. Please type "Y" twice to start with restore process.  
![oft_linux_4](oft_linux_4.jpg)

7. Please select "power off". Please remove DC input and USB disk and then power on system again.  
![oft_linux_5](oft_linux_5.jpg)

8. Default user name is "aes" and password is "123456".  
![oft_linux_7](oft_linux_7.jpg)