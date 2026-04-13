# ACP-IMX6POS Ubuntu

## Build and install Ubuntu image for ACP-IMX6POS

Here you can find instruction to setup development environment for Ubuntu source code for ACP-IMX6POS and the way to install it on eMMC or SD card. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

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
[Initializing a Build Environment ↗](https://source.android.com/docs/setup/start/requirements)

### Download Source code
> [!NOTE]
> Please connect Avale FAE/Sales to get source code.

### Compile Ubuntu Source code
Please following instruction below to compile Android source code  

#### Compile Kernel
```bash
cd linux-imx 
./run.sh e9697xxxxxx -j32 modules headers
```
#### Compile Uboot
```bash
cd uboot-imx
./run.sh e9697xxxxxx -j32 emmc
```
> [!NOTE]
> If want to flash image to SD, replace emmc to sd  

You can find Kernel image files in path `linux-imx/out`  
You can find Uboot image files in path `uboot-imx/out`  

## Install image

[Flash_image(ACP-IMX6POS).pdf](https://webdownload.avalue.com.tw/wiki/RISC/ACP-IMX6POS/Document/Flash_image(ACP-IMX6POS).pdf)

### Download MfgTool from Hyperlink below

#### Dual Lite version
| Image        | Download Link|
|:-------------|:-------------|
| Ubuntu12.04  | [無檔案]() |

#### Quad version
| Image        | Download Link|
|:-------------|:-------------|
| Ubuntu12.04  | [無檔案]() |

## Document
| Document               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [Download](https://github.com/AE-public/wiki/releases/download/ACP-IMX6POS/ACP-IMX6POS_2312423316.pdf) |
| Datasheet B1           | [Download](https://github.com/AE-public/wiki/releases/download/ACP-IMX6POS/ACP-IMX6POS-B1_2312423312.pdf) |
| Mechanical Drawing     | [無檔案]() |
| 3D Drawing (step file) | [無檔案]() |
