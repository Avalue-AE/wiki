# RQM-IMX6 Ubuntu

## Build and install Ubuntu image for RQM-IMX6

Here you can find instruction to setup development environment for Android source code for RQM-IMX6 and the way to install it on eMMC. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

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

#### Compile Ubuntu Source code
Please following instruction below to compile Android source code  

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
You can find Uboot image files in path `uboot-imx/out`  

## Install image

[無檔案]()

### Download MfgTool for Android from Hyperlink below

#### Dual Lite version
| OS           | File  |
|:-------------|:-------------|
| Ubuntu12.04  | [無檔案]() |

#### Quad version
| OS           | File  |
|:-------------|:-------------|
| Ubuntu12.04  | [無檔案]() |

## Document
| Documant               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [無檔案]() |
| User's Manual          | [無檔案]() |
| Mechanical Drawing     | [無檔案]() |
| 3D Drawing (step file) | [無檔案]() |  
