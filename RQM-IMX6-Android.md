# RQM-IMX6 Android

## Build and install Android image for RQM-IMX6

Here you can find instruction to setup development environment for Android source code for RQM-IMX6 and the way to install it on eMMC or SD card. With this guideline, user will be able to setup the system easily and test all the functions with the system.  

### Setup Build Environment

Please following command below to install Oracle JDK6.0 on Ubuntu 12.04 or above.  
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

#### Compile Android image
Please following instruction below to compile Android source code  

### Compile Android source code
```bash
$cd android-4
./run.sh
```

You can find Android image files in path `/out/target/product/smarc`  
![rqm-imx6_compiler1](images/RQM-IMX6-Android/rqm-imx6_compiler1.png)

## Install image

[無檔案]()

## Download MfgTool for Android from Hyperlink below

### Dual Lite version
| OS           | Download Link|
|:-------------|:-------------|
| Android6.0   | [無檔案]() |
| Ubuntu12.04  | [無檔案]() |
| Yocto2.1     | [無檔案]() |

### Quad version
| OS           | File  |
|:-------------|:-------------|
| Ubuntu12.04  | [無檔案]() |
| Yocto2.1     | [無檔案]() | 

## Document
| Documant               | Download Link|
|:-----------------------|:-------------|
| Datasheet              | [無檔案]() |
| User's Manual          | [無檔案]() |
| Mechanical Drawing     | [無檔案]() |
| 3D Drawing (step file) | [無檔案]() | 
