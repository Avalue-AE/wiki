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

[User guide by MfgTool](https://github.com/AE-public/wiki/releases/download/RSC-IMX61/Flash.image.RSC-IMX61.pdf)

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

