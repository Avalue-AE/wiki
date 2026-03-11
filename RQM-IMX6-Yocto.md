# RQM-IMX6 Yocto

## Build and install Yocto image for RQM-IMX6

Here you can find instruction to setup development environment for Yocto source code for RQM-IMX6 and the way to install it on eMMC. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

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

#### Compile Android Source code

Please following instruction below to compile Android source code  
```bash
$cd Android
./run.sh -j4
```
You can find all image files in path `Android/out/target/product/smarc/`  

| Image File     | Description                       |
|----------------|-----------------------------------|
| boot.img       | kernel image Download Link        |
| recovery.img   | recovery image Download Link      |
| system.img     | system image Download Link        |
| u-boot-6q.bin  | bootloader for IMX6-POS Quad core |
| u-boot-6dl.bin | bootloader for IMX6-POS Dual lite |

Please copy all of them to path `Android-MfgTools\Image\smarc\android` of MfgTool folder.  

## Install image

[無檔案]()

### Download MfgTool for Android from Hyperlink below

#### Dual Lite version
| OS           | File  |
|:-------------|:-------------|
| Yocto2.1(4.1.15)     | [無檔案]() |

#### Quad version
| OS           | File  |
|:-------------|:-------------|
| Yocto2.1(4.1.15)     | [無檔案]() |

## Document
| Documant               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [無檔案]() |
| User's Manual          | [無檔案]() |
| Mechanical Drawing     | [無檔案]() |
| 3D Drawing (step file) | [無檔案]() |
