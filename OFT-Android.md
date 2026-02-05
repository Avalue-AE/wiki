# How to flash Android image file

## Instruction to flash Android image with USB Installer

(You can choose either this method or entering DnX Mode, instruction provided in next section)  

| Document                        | Download Link          |
| :------------------------------ | :--------------------- |
| USB installer                   | [Download]()           |
| A44_0.0.46                      | [Android image file]() |
| A44_0.0.95 (With file manager)  | [Android image file]() |
| A44_0.0.106 (With file manager) | [Android image file]() |
| A51_0.0.24                      | [Android image file]() |
| A51_0.0.39                      | [Android image file]() |  

1. Update BIOS to latest 64bit version if needed. You can refer to this link to update BIOS.  
2. Format the USB disk with FAT32, untar the `USB_Installer.7z`.  
    ![flash_android_2](images/OFT-Android/flash_android_2.png)  
3. Express the Android image as below.  
    ![flash_android_3](images/OFT-Android/flash_android_3.png)  
4. Express `/flash_files/build-user/byt_t_crv2_64-user-fastboot-BCXXX-VXXXX.zip`.  
    ![flash_android_4](images/OFT-Android/flash_android_4.png)  
5. Choose the actual image as below, then replace those in the USB_Installer.  
    ![flash_android_5](images/OFT-Android/flash_android_5.png)  
> [!NOTE]  
> Notice that your USB_Installer should be like the file tree as below, and those redmarked ones are which you should replace with.  
> ![flash_android_5-1](images/OFT-Android/flash_android_5-1.png)  
> And your USB_Installer should be like as below.
> ![flash_android_5-2](images/OFT-Android/flash_android_5-2.png)  
1. Copy files under USB_Installer to your USB drive and plug in your device, and ensure that you connect keyboard with your device. 
2. Power on your device and press `F12` to enter Boot Manager, then choose the USB you plug in.
    ![bios_2](images/OFT-Android/bios_2.png)
3. Auto load would start after few seconds.  
    ![flash_android_8](images/OFT-Android/flash_android_8.png)  
> [!NOTE]
> Notice that you should unplug your USB while finishing loading image, or it would reload again.  
1. Reboot and enter Android system.  
    ![flash_android_10](images/OFT-Android/flash_android_10.png)  

## Instruction to flash Android image with DnX Mode

Android image file download Link  
[Android image file]()  

1. Please make sure you already update BIOS to latest 64bit version. You can refer to this link to update BIOS.  
2. Please refer to this [link]() to install `Intel Platform Flash tool Lite` and `Intel® Android* USB Drivers`.  
3. Plug in membrane keypad test cable on `JTB1` of the system. Here is approval sheet of approval sheet of [membrane keypad]() & [cable]().  
    ![key_1](images/OFT-Android/key_1.png)  
    ![key_2](images/OFT-Android/key_2.png)  
    ![key_3](images/OFT-Android/key_3.png)  
    ![key_4](images/OFT-Android/key_4.png)  
4. Please remove all the USB devices from OFT-XXW01 before you power on the system. Press `-` & `+` key of keypad when power on to get into DNX mode. If you have problem to get into DNX mode, please reflash BIOS again to solve this issue.
    ![key_5](images/OFT-Android/key_5.png)  
    ![6225125](images/OFT-Android/6225125.png)  
5. If you do not have membrane keypad on hand, you can use the way below to get into DNX mode.  
    1. Remove shielding cover of motherboard by removing 4 screws.
        ![dnx1](images/OFT-Android/dnx1.png)  
    2. Use the 4 screws to fix motherboard well and plug in Micro USB cable.
        ![dnx2](images/OFT-Android/dnx2.png)  
    3. Press `SW2` before you power on the system. Power on system right now and then you will see system already in DNX mode. You can release `SW2` right now.  
        ![dnx3](images/OFT-Android/dnx3.png)  
6. Run Intel Platform Flash tool and select `flash-EraseFactory.xml` in path `\2014WW46_BCX11_Intel_A44_0.0.46\flash_files\blankphone`.  
   ![flash_1](images/OFT-Android/flash_1.png)  
   Press “Start to flash” to erase eMMC of the system.  
   ![flash_2](images/OFT-Android/flash_2.png)  
7. Once you finish erase process, please select `flash.xml` in path `\2014WW46_BCX11_Intel_A44_0.0.46\flash_files\build-user\byt_t_crv2_64-user-fastboot-BCX11-V0.0.46` and then press `Start to flash`.
   ![flash_3](images/OFT-Android/flash_3.png)  
8. Once you finish the process, OFT-XXW01 will reboot automatically and get into Android.
   ![flash_4](images/OFT-Android/flash_4.png)  
