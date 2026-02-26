# How to install RFID driver on Ubuntu 14.04 or Fedora 21

## For installation on Ubuntu  

1. install need library  
``` 
  sudo apt-get install libudev-dev libusb-1.0-0-dev libfox-1.6-dev 
  sudo apt-get install autotools-dev autoconf automake libtool 
  sudo apt-get install g++  
  ```


2.make and install hidapi  
```
  tar jxvf <media path>/hidapi-0.8.0.tar.bz2 
  cd hidapi-0.8.0/ 
  ./bootstrap
  ./configure 
  make 
  sudo make install 
  sudo ldconfig 
```

3.make test api  
```
  tar jxvf <media path>/rfidtest.tar.bz2 
  cd rfidtest 
  make
```

4.Test RFID
```
  sudo ./rfidtest 
  ```


## For installation on Fedora


1.install need library  
```
  sudo yum install  systemd-devel libusbx-devel
  sudo yum install automake autoconf libtool
  sudo yum install gcc-c++
```

2.make and install hidapi  
```
  tar jxvf <media path>/hidapi-0.8.0.tar.bz2
  cd hidapi-0.8.0/
  ./bootstrap
  ./configure
   make 
   sudo make install
   sudo sh -c "echo '/usr/local/lib' >> /etc/ld.so.conf"
   sudo ldconfig  
```

4.make test api  
```
  tar jxvf <media path>/rfidtest.tar.bz2
  cd rfidtest
  make
```
5.Test RFID 
```
  sudo ./rfidtest
```