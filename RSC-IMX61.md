# RSC-IMX61 Android

## Build and install Android image for RSC-IMX61

Here you can find instruction to setup development environment for Android source code for RSC-IMX61 and the way to install it on eMMC or SD card. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

### Setup Build Environment

Please following command below to install Oracle JDK6.0 on Ubuntu 12.04
or above.  
```bash
$sudo apt-get install python-software-properties
$sudo add-apt-repository ppa:webupd8team/java
$sudo apt-get update
$sudo apt-get install oracle-java6-installer
$sudo update-alternatives --config java
```

Please refer to hyperlink below to setup development environment  
[Initializing a Build Environment ↗](https://source.android.com/docs/setup/start/requirements)

### Download Source code
> [!NOTE]
> Please connect Avale FAE/Sales to get source code.

### Compile Android Source code

Please following instruction below to compile Android source code  

#### Compile Android image
```bash
$cd android4 
./run.sh
```
Select 24 to compile Android4.4 image  
![rsc-imx61_android_compiler1](images/RSC-IMX61-Android/rsc-imx61_android_compiler1.png)
![rsc-imx61_android_compiler2](images/RSC-IMX61-Android/rsc-imx61_android_compiler2.png)

You can find Android image files in path `linux-imx/out/target/product/aib`  
![rsc-imx61_android_compiler3](images/RSC-IMX61-Android/rsc-imx61_android_compiler3.png)

## Install image guide

[RSC-IMX61_Mfg2.3.3_eMMC_SD_Program guide](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Flash.image.RSC-IMX61.pdf)

## Download MfgTool for Android from Hyperlink below

### Dual Lite version
| Image        | Download Link|
|:-------------|:-------------|
| Android6.0   | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Android6.0_Dual_Lite.zip) |  

# RSC-IMX61 Ubuntu

## Build and install Ubuntu image for RSC-IMX61

Here you can find instruction to setup development environment for Android source code for RSC-IMX61 and the way to install it on eMMC. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

## Setup Build Environment

Please following command below to install Oracle JDK6.0 on Ubuntu 12.04 or 14.04  
```bash
$sudo apt-get install python-software-properties
$sudo add-apt-repository ppa:webupd8team/java
$sudo apt-get update
$sudo apt-get install oracle-java6-installer
$sudo update-alternatives --config java
```
Please refer to hyperlink below to setup development environment  
[Initializing a Build Environment ↗](https://source.android.com/docs/setup/start/requirements)

## Download Source code
> [!NOTE]
> Please connect Avale FAE/Sales to get source code.

## Compile Ubuntu Source code

Please following instruction below to compile Ubuntu source code  
### Compile Kernel
```bash
$cd rsc-imx61/linux-imx
./run.sh aib-imx6 -j4
```

### Compile Uboot
```bash
$cd rsc-imx61/uboot-imx
./run.sh q-1g
```

The uboot compile parameter would be related with board version.  
| Image File | Description                |
|:-----------|:---------------------------|
| q-1g       | Quad CPU with 1G DDR3      |
| q-2q       | Quad CPU with 2G DDR3      |
| dl-1g      | Dual Lite CPU with 1G DDR3 |
| dl-2g      | Dual Lite CPU with 2G DDR3 |

You can find Kernel image in path `rsc-imx61/linux-imx/arch/arm/boot`  
![rsc-imx61_kernel_image_ubuntu](images/RSC-IMX61-Ubuntu/rsc-imx61_kernel_image_ubuntu.png)  

You can find Uboot image in path `rsc-imx61/linux-imx/arch/arm/boot`  
![rsc-imx61_uboot_image_ubuntu](images/RSC-IMX61-Ubuntu/rsc-imx61_uboot_image_ubuntu.png)  

## Install image guide

[RSC-IMX61_Mfg2.3.3_eMMC_SD_Program guide](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Flash.image.RSC-IMX61.pdf)

## Download MfgTool for Android from Hyperlink below

### Dual Lite version
| Image        | Download Link|
|:-------------|:-------------|
| Ubuntu12.04  | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Ubuntu12.04_Dual_Lite.zip) |

### Quad version
| Image        | Download Link|
|:-------------|:-------------|
| Ubuntu12.04  | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Ubuntu12.04_Quad.zip) |

# RSC-IMX61 Yocto

## Build and install Yocto image for RSC-IMX61

Here you can find instruction to setup development environment for Yocto source code for RSC-IMX61 and the way to install it on eMMC. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

### Setup Build Environment

The recommended minimum Ubuntu version is 14.04 but builds for Jethro works on 12.04 or later.  
Earlier versions maycause the Yocto Project build setup to fail, because it requires python versions only available starting wtih Ubuntu 12.04.  
A Yocto Project build requires that some packages be installed for the build that are documented under the Yocto Project.  

Essential Yocto Project host packages are:
```bash
$sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
build-essential chrpath  socat  libsdl1.2-dev
```

i.MX layers host packages for a Ubuntu 12.04 or 14.04 host setup are:  
```bash
$sudo apt-get install libsdl1.2-dev xterm  sed cvs subversion coreutils texi2html \
docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake groff curl lzop asciidoc 
```

i.MX layers host packages for a Ubuntu 12.04 host setup only are:  
```bash
$sudo apt-get install uboot-mkimage 
```

i.MX layers host packages for a Ubuntu 14.04 host setup only are:  
```bash
$sudo apt-get install u-boot-tools
```

### Download Source code
> [!NOTE]
> Please connect Avale FAE/Sales to get source code.  

### Compile Yocto Source code

Please following instruction below to compile Ubuntu source code  

#### Compile Kernel
```bash
$cd linux-imx 
./run.sh e9697xxxxxx -j32 modules headers
```

#### Compile Uboot
```bash
$cd uboot-imx
./run.sh e9697xxxxxx -j32 emmc
```

> [!NOTE]
> If want to flash image to SD, replace emmc to sd

You can find Kernel image files in path `linux-imx/out`  
![rsc-imx61_yocto_kernel](images/RSC-IMX61-Yocto/rsc-imx61_yocto_kernel.png)  

You can find Uboot image files in path `uboot-imx/out`  
![rsc-imx61_yocto_uboot](images/RSC-IMX61-Yocto/rsc-imx61_yocto_uboot.png)  

## Install image guide

[RSC-IMX61_Mfg2.3.3_eMMC_SD_Program guide](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Flash.image.RSC-IMX61.pdf)

## Download MfgTool for Android from Hyperlink below

### Dual Lite version
| Image        | Download Link|
|:-------------|:-------------|
| Yocto2.1     | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Yocto2.1_Dual_Lite.zip) |

### Quad version
| Image        | Download Link|
|:-------------|:-------------|
| Yocto2.1     | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Yocto2.1_Quad.zip) | 

## Document
| Documant               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/rsc-imx61.pdf) |
| Mechanical Drawing     | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/rsc-imx6_150525.pdf) |
| 3D Drawing (step file) | [Download](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/rsc-imx6_3d_150525.zip) |