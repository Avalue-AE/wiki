# Linux X86 API  

**Avalue Driver**  

Linux Kernel driver for Avalue product.  
- core: it85x8, nct61x6, pca9555 chip implementation.  
- library: dio, hwm, lvds, pwm, wdt.. kernel sysfs/ioctl implementation library.  
- config: function_control, register_control define for this programme.  
- product: avalue product board name routing for config.  
  
## AlmaLinux 8.8  

```bash
# create connection 
nmcli connection up enp1s0 # enp1s0 is network interface device name
 
# 
sudo dnf update
sudo dnf clean all
 
# install dependency packages
sudo dnf group install "Development Tools"
```  

## Centos  
```bash
# install gcc, make first
sudo yum -y install git gcc make elfutils-libelf-devel
 
# in package at your installation usb storage find the kernel-devel-`uname -r`.rpm
rpm -ivh kernel-devel-`uname -r`.rpm
 
# centos 7
# open kernel log
sudo vim /etc/rsyslog.conf
# alter line at kernel log
kern.*      /var/log/kernel
```  

## Ubuntu  
```bash
sudo apt update
sudo apt -y install gcc make linux-headers-`uname -r`
```

## Complier kernel module  
```bash
tar zvxf Avalue_driver.tar.gz
cd Avalue_driver
 
## Parameter
## DRIVER : complier the module you want
## DEBUG=ON : debug mode on, switch pr_debug on/off
## MODULE_NAME : kernel driver module .ko file name
## BOARD_NAME : specify board name if dmi(bios) does not work
 
## Action
## clean : remove complier temp file
## build : complier module
## install : insmod module
## uninstall : rmmod module
## api : complier api
## load_on_boot : auto load kernel module on boot
 
# GPIO
sudo make DRIVER=DIO
 
# PWM
sudo make DRIVER=PWM
 
# WDT
sudo make DRIVER=WDT
 
# HWM
sudo make DRIVER=HWM
 
# LVDS
sudo make DRIVER=LVDS
 
# INFO
sudo make DRIVER=INFO
```

## DKMS (Dynamic Kernel Module Support)  
```bash
sudo apt install -y dkms
sudo cp -rf Avalue_driver-${version} /usr/src
sudo dkms add -m Avalue_driver -v ${version}
sudo dkms build -m Avalue_driver -v ${version}
sudo dkms install -m Avalue_driver -v ${version}
 
# add the kernel module name into /etc/modules
# ex. watchdog
echo "wdt" >> /etc/modules
```  
manual board name in dkms.conf  
> [!NOTE] 
> MAKE = `script/buildall.sh BOARD_NAME=ECM-TGU`  

## GPIO sysfs  
```bash
# Default device node
cd /sys/class/misc/dio
 
# Export dio port:
echo 0 > export
 
# Value low/high
echo 0/1 > dio0/value
echo low/high > dio0/value
cat value
 
# Direction input/output
echo 0/1 > dio0/direction
echo input/output > dio0/direction
cat dio0/direction
 
# Unexport dio port:
echo 0 > unexport
```  
Sysfs reference from [https://www.kernel.org/doc/Documentation/gpio/sysfs.txt](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt)  

## PWM sysfs  
```bash
# Default device node
cd /sys/class/misc/pwm
 
# Change to $device_name(Backlight, Fan_Cpu..) pwm device element as you want
cd $device_name
 
# Value 0x00~0xFF:
echo 0~255 > value
cat value
 
# Level 0~100:
echo 0~100 > level
cat level
```  

## WDT sysfs  
```bash
# Default device node
cd /sys/class/misc/wdt
 
# Start watchdog countdown:
echo > start
 
# Stop watchdog countdown:
echo > stop
 
# Ping reset watchdog count:
echo > ping
 
# Restart set watchdog count at 1 second, os restart:
echo > restart
 
# Timeleft get watchdog count:
cat timeleft
 
# Timeout set watchdog count at 120 second:
echo 120 > timeout
cat timeout
```  

Sysfs reference from [https://www.kernel.org/doc/Documentation/watchdog/watchdog-kernel-api.txt](https://www.kernel.org/doc/Documentation/watchdog/watchdog-kernel-api.txt)  

## HWM sysfs  
```bash
# Default device node
cd /sys/class/misc/hwm
 
# Change to $device_name(temp_cpu, vin_core..) hwm device element as you want
cd $device_name
 
# Value(R) sensor value or device value:
cat value
 
# Unit(R) Voltage/RPM/Celsius degree:
cat unit
 
# PWM(R/W) Fan only(control pwm)
cat pwm
echo 100 > pwm
```  

## LVDS sysfs  
```bash
# Default device node
cd /sys/class/misc/lvds
 
# Freqency (R/W) Backlight PWM Clock Mode
# 0=> 200, 1=> 300, 2=> 400, 3=> 500, 4=> 700, 5=> 1K,
# 6=> 2K, 7=> 3K, 8=> 5K, 9=> 10K, 0a=>20K
cat frequency
echo 1~10 > frequency
 
# Percentage (R/W) Backlight PWM Percentage
cat percentage
echo 1~100 > percentage
 
# Percentage (R/W) Backlight PWM
cat pwm
echo 0~255 > pwm
 
# Type LVDS panel type for ch7511
# 1024x768, 24/1
# 800x600, 18/1
# 1024x768, 18/1
# 1366x768, 18/1
# 1024x600, 18/1
# 1280x800, 18/1
# 1920x1200, 24/2
# 1920x1080, 24/2
# 1280x1024, 24/2
# 1366x768, 24/1
# 1920x1080, 24/2
# 1680x1050, 24/2
cat type
echo 0~11 > type
```  

## INFO sysfs  
```bash
# Default device node
cd /sys/class/misc/info
 
# Bios(R) information for bios:
cat bios/*
 
# Board(R) information for board:
cat board/*
 
# Cpu(R) information for cpu:
cat cpu/*
 
# Product(R) information for product:
cat product/*
 
# Ec(R)	information for EC chip:
cat ec/*
```  

## MISC sysfs  
```bash
# Default device node
cd /sys/class/misc/misc
 
# Change to register_name(usb_standby_power, usb_uptime_power.. ) as you want
cd $register_name
```  

## Support product  
- Define in `config/product.h` (base on bios `BOARD_NAME` and `/sys/class/dmi/id/board_name`)  
- More detail in `./doc/index.html`  
- If have any question, please contact Avalue PM/AE/Sales for help.  

## Change log  
| Date       | Version | Describe                                                                                            |
| :--------- | :------ | :-------------------------------------------------------------------------------------------------- |
| 2024/12/19 | 3.1.34  | support EPX-ASLP, EMS-MTU, EMS-MTH, EMX-MTLP, ECM-MTL, EMX-KX60G.                                   |
| 2024/12/02 | 3.1.33  | modify ECM-TGUC pwm1=FAN_CPU.                                                                       |
| 2024/08/21 | 3.1.32  | support ESM-KX60G, ESM-ASLC, NUC-RPU.                                                               |
| 2024/06/12 | 3.1.31  | support misc function for EC controller.                                                            |
| 2024/05/02 | 3.1.30  | fix issue with test wdt will cause file corruption.                                                 |
| 2024/03/21 | 3.1.29  | support ECM-EHL3.                                                                                   |
| 2024/03/21 | 3.1.28  | support build share library, and add feature for network interface information.                     |
| 2024/02/05 | 3.1.27  | fix issue with cpu temperature reading, when value bigger than 127 are considered negative.         |
| 2024/02/05 | 3.1.26  | support ESM-EHL, EBM-EHLS.                                                                          |
| 2024/02/05 | 3.1.25  | support SupperIO NCT6106, NCT6126 and ECM-TGU.                                                      |
| 2023/12/25 | 3.1.24  | support ECM-TGUC, ESM-RPL, ESM-RPLC, EMX-RPLP, ECM-ASL, EMX-ASLP.                                   |
| 2023/12/06 | 3.1.23  | support ESM-EHLC.                                                                                   |
| 2023/12/04 | 3.1.22  | support EPX-EHLP.                                                                                   |
| 2023/07/19 | 3.1.21  | support ARC-ADLN, EQM-EHL.                                                                          |
| 2023/03/31 | 3.1.20  | support EAX-C246P.                                                                                  |
| 2023/03/09 | 3.1.19  | support ESM-TGH.                                                                                    |
| 2023/01/12 | 3.1.18  | support NCM-TGU, NCM-EHL.                                                                           |
| 2022/11/08 | 3.1.17  | support EZX-EHLP. fix bug when dio driver export/unexport channel out of range kernal panic.        |
| 2022/09/26 | 3.1.16  | fix bug with out_of_memory issue (kernel oom-killer).                                               |
| 2022/06/24 | 3.1.15  | fix bug with BOARD_NAME parameter, board name not found issue.                                      |
| 2022/05/13 | 3.1.14  | support ESM-ZXE.                                                                                    |
| 2022/05/10 | 3.1.13  | fix bug with lib/wdt.c, cannot override the timeout from user space.                                |
| 2022/03/22 | 3.1.12  | support TPB-04114.                                                                                  |
| 2022/01/14 | 3.1.11  | support EBM-EHLR.                                                                                   |
| 2021/10/13 | 3.1.10  | support EMX-VX11.                                                                                   |
| 2021/10/12 | 3.1.9   | fix issue with if get board name from dmi(bios) does not work.                                      |
| 2021/09/24 | 3.1.8   | support EMX-SKLUP.                                                                                  |
| 2021/08/16 | 3.1.7   | support ESM-BYT2.                                                                                   |
| 2021/08/05 | 3.1.6   | support ec dio function for ESM-APLM.                                                               |
| 2021/07/14 | 3.1.5   | support product ECM-WHL. fix bug with miscdevice.c at ioctl return result/error issue.              |
| 2021/02/19 | 3.1.4   | merge Avalue_api into this project.                                                                 |
| 2021/01/05 | 3.1.3   | support product EMS-TGL, NUC-APL, EMX-H310P.                                                        |
| 2020/11/30 | 3.1.0   | refactor Avalue_driver programme struct.                                                            |
| 2020/07/14 | 3.0.0   | support wdt, pwm, lvds, hwm, gpio, info(system information) driver. support interface ioctl, sysfs. |
