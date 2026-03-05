# Instruction to flash Android image with USB Installer
(You can choose either this method or entering DnX Mode, instruction provided in next section)  

USB installer download Link  
[無檔案]()  

Android image file A44_0.0.23 download Link  
[無檔案]() 

Android image file A44_0.0.31 download Link  
[無檔案]()  

Android image file A51_0.0.14 download Link  
[無檔案]()  

1. Update BIOS to latest 64bit version if needed. You can refer to this [Link](How-to-update-BIOS-for-OFT-07W01) to update BIOS.  
   
2. Format the USB disk with FAT32, untar the USB_Installer.7z  
(Screenshot for reference only)  
![flash_android_2](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_2.jpg)

3. Express the Android image as below  
(Screenshot for reference only)  
![flash_android_3](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_3.jpg)

4. Express /flash_files/build-user/byt_t_crv2_64-user-fastboot-BCXXX-VXXXX.zip  
(Screenshot for reference only)  
![flash_android_4](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_4.jpg)

5. Choose the actual image as below, then replace those in the USB_Installer  
(Screenshot for reference only)  
![flash_android_5](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_5.jpg) 

Notice that your USB_Installer should be like the file tree as below, and those redmarked ones are which you should replace with.  
![flash_android_5-1](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_5-1.jpg)  
  
And your USB_Installer should be like as below,  
(Screenshot for reference only)  
![flash_android_5-2](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_5-2.jpg)  

6. Copy files under USB_Installer to your USB drive and plug in your device, and ensure that you connect keyboard with your device.  

7. Power on your device and press F12 to enter Boot Manager, then choose the USB you plug in.  
![bios_2](images/How-to-flash-Android-image-file-for-OFT-07W01/bios_2.jpg)  

8. Auto load would start after few seconds.  
![flash_andriod](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_8.jpg)  

> [NOTE]  
>9. Notice that you should unplug your USB while finishing loading image, or it would reload again.  
  
10. Reboot and enter Android system  
![flash_andriod_10](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_android_10.jpg)  


# Instruction to flash Android image with DnX Mode

Android image file download Link  
[無檔案]() 

1. Please make sure you already update BIOS to latest 64bit version. You can refer to this [Link](How-To-Update-BIOS) to update BIOS.  
2. Please refer to this [Link](https://www.intel.com/content/www/us/en/developer/topic-technology/open/overview.html?langredirect=1) to install **Intel Platform Flash tool Lite** and **Intel® Android* USB Drivers**.  
3. Plug in membrane keypad test cable on JTB1 of the system. Here is approval sheet of approval sheet of [membrane keypad](https://github.com/AE-public/wiki/releases/download/How-to-flash-Android-image-file-for-OFT-07W01/e1971120102r.pdf) & [cable](https://github.com/AE-public/wiki/releases/download/How-to-flash-Android-image-file-for-OFT-07W01/e170x210020r.pdf) 
![key_1](images/How-to-flash-Android-image-file-for-OFT-07W01/key_1.jpg)  
![key_2](images/How-to-flash-Android-image-file-for-OFT-07W01/key_2.jpg)  
![key_3](images/How-to-flash-Android-image-file-for-OFT-07W01/key_3.jpg)  
![key_4](images/How-to-flash-Android-image-file-for-OFT-07W01/key_4.jpg)  

4. Please remove all the USB devices from OFT-XXW01 before you power on the system. Press "-" & "+" key of keypad when power on to get into DNX mode. If you have problem to get into DNX mode, please reflash BIOS again to solve this issue.  
![key_5](images/How-to-flash-Android-image-file-for-OFT-07W01/key_5.jpg)  
![6225125](images/How-to-flash-Android-image-file-for-OFT-07W01/6225125.jpg)  

5. If you do not have membrane keypad on hand, you can use the way below to get into DNX mode.  
1.Remove shielding cover of motherboard by removing 4 screws.  
![dnx1](images/How-to-flash-Android-image-file-for-OFT-07W01/dnx1.jpg)
2.Use the 4 screws to fix motherboard well and plug in Micro USB cable.  
![dnx2](images/How-to-flash-Android-image-file-for-OFT-07W01/dnx2.jpg)  
3.Press SW2 before you power on the system. Power on system right now and then you will see system already in DNX mode. You can release SW2 right now.  
![dnx3](images/How-to-flash-Android-image-file-for-OFT-07W01/dnx3.jpg)  

6. Run **Intel Platform Flash tool** and select "**flash-EraseFactory.xml**" in path "**\2014WW46_BCX11_Intel_A44_0.0.46\flash_files\blankphone**"  
![flash_1](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_1.jpg)  

Press "Start to flash" to erase eMMC of the system.  
![flash_2](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_2.jpg)  

7. Once you finish erase process, please select "**flash.xml**" in path "**\2014WW46_BCX11_Intel_A44_0.0.46\flash_files\build-user\byt_t_crv2_64-user-fastboot-BCX11-V0.0.46**" and then press "Start to flash"  
![flash_3](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_3.jpg)  

8. Once you finish the process, OFT-07W01 will reboot automatically and get into Android.  
![flash_4](images/How-to-flash-Android-image-file-for-OFT-07W01/flash_4.jpg)  