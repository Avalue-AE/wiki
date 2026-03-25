# ACP-IMX6POS Android

## Build and install Android image for ACP-IMX6POS

Here you can find instruction to setup development environment for Android source code for RSC-IMX61 and the way to install it on eMMC. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

### Setup Build Environment

Please following command below to install Oracle JDK6.0 on Ubuntu 12.04 or 14.04  
```bash
$sudo apt-get install python-software-properties
$sudo add-apt-repository ppa:webupd8team/java
$sudo apt-get update
$sudo apt-get install oracle-java6-installer
$sudo update-alternatives --config java
```
Please refer to hyperlink below to setup development environment  
[Initializing a Build Environment](https://source.android.com/docs/setup/start/requirements)

### Download Source code

> [!NOTE]
> Please connect Avale FAE/Sales to get source code.

### Compile Android Source code

Please following instruction below to compile Android source code  
```bash
cd Android
./run.sh -j4
```

You can find all image files in path `Android/out/target/product/smarc/`
![acp-imx6pos_compiler1.png](images/ACP-IMX6POS-Android/acp-imx6pos_compiler1.png)

| Image File     | Description                       |
|:---------------|:----------------------------------|
| boot.img       | kernel image file                 |
| recovery.img   | recovery image file               |
| system.img     | system image file                 |
| u-boot-6q.bin  | bootloader for IMX6-POS Quad core |
| u-boot-6dl.bin | bootloader for IMX6-POS Dual lite |

Please copy all of them to path `Android-MfgTools\Image\smarc\android` of MfgTool folder.

### Install image

[無檔案]()

## Download MfgTool for Android from Hyperlink below

### Dual Lite version
| Image        | Download Link|
|:-------------|:-------------|
| Android6.0   | [無檔案]() |

## Document
| Document               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [無檔案]() |
| User's Manual          | [無檔案]() |
| Mechanical Drawing     | [無檔案]() |
| 3D Drawing (step file) | [無檔案]() |