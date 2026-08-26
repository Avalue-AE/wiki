# How to test GPIO function on Windows

Requested File Download Link below  
[無檔案]()


1. Extract all the files “Demo.7z”, “drv.7z”, “exe.7z”. 

2. Please check your BIOS version whether it is most updated, if not please update the BIOS for GPIO TEST, you can refer the instruction from the link below and execute “BCX11i32.nsh” for BIOS updating.  
[BIOS Update Link](How-To-Update-BIOS)  

>[!NOTE]
You can press "F2" to check BIOS version when system booting up.

3. Please install windows 8.1 and all drivers. Driver download link.
[無檔案]()
or Windows 10 driver
[無檔案]()

         

4. Move to the “Device Manager” then right click the “unknown device” to install the driver “I2C TCA9555 Driver” from the file folder “drv”.

5. Open the cmd in windows.

6. Move to the file folder “exe” and execute the file “blink.exe” or “test.exe” for test GPIO.

7. You can refer the source code from the file folder “Demo”.

8. You need to prepare the loopback connector first, make the GPIO output port connect with the input port as below.

DIO_GP10->DIO_GP20 
DIO_GP11->DIO_GP21  
DIO_GP12->DIO_GP22  
DIO_GP13->DIO_GP23  
DIO_GP14->DIO_GP24  
DIO_GP15->DIO_GP25  
DIO_GP16->DIO_GP26  
DIO_GP17->DIO_GP27  

![gpio](../imagesHow-to-test-GPIO-function-on-Windows/gpio.jpg)  