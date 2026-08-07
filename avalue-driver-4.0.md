 ## [Avalue Linux Driver Suite](Avalue-Linux-Driver-Suite)

* [CLAUDE.md](CLAUDE)  
* [GPIO.md](GPIO)  
* [HWM.md](HWM)  
* [Kbuild](Kbuild)  
* [Makefile](Makefile)  
* [.clang-format](.clang-format)  
* [.editorconfig](.editorconfig)  
* [.gitignore](.gitignore)  

<details>
<summary>Test</summary>  

* [build-matrix](test/build-matrix.sh)
* [config sweep](test/config-sweep.sh)
* [test gpio](test/test-gpio.sh)
* [test infrastructure](Test-infrastructure)
</details>  

<details>
<summary>src</summary>  

* [log.h](src/log.h)  

<details>  
<summary>config</summary>  

* [config.h](src/configs/config.h)  
  </details>

<details>
<summary>drivers</summary> 

* [gpio.c](src/drivers/gpio.c)  
* [hwmon.c](src/drivers/hwmon.c)  
* [misc.c](src/drivers/misc.c)  
* [watchdog.c](src/drivers/watchdog.c) 
</details>  

<details>
<summary>hal</summary>

* [bctrl.h](src/hal/bctrl.h)  
* [bytes.h](src/hal/bytes.h)  
* [gpio.h](src/hal/gpio.h)  
* [hwm.h](src/hal/hwm.h)  
* [ioport.h](src/hal/ioport.h)  
* [misc.h](src/hal/misc.h)  
* [wdt.h](src/hal/wdt.h)   
</details>  

<details>
<summary>ec</summary> 

* [ite_gpio.c](src/hal/ec/ite_gpio.c)  
* [ite_hwm.c](src/hal/ec/ite_hwm.c)  
* [ite_misc.c](src/hal/ec/ite_misc.c)  
* [ite_wdt.c](src/hal/ec/ite_wdt.c)  
* [ec.h](src/hal/ec/ec.h)  
* [ite.c](src/hal/ec/ite.c)  
* [ite.h](src/hal/ec/ite.h)  
</details>

<details>
<summary>sio</summary>

* [f81966.c](src/hal/sio/f81966.c)  
* [f81966.h](src/hal/sio/f81966.h)  
* [f81966_hwm.c](src/hal/sio/f81966_hwm.c)  
* [f81966_wdt.c](src/hal/sio/f81966_wdt.c)  
* [nct61x6d.c](src/hal/sio/nct61x6d.c)  
* [nct61x6d.h](src/hal/sio/nct61x6d.h)  
* [nct61x6d_hwm.c](src/hal/sio/nct61x6d_hwm.c)  
* [nct61x6d_wdt.c](src/hal/sio/nct61x6d_wdt.c)  
* [sio.h](src/hal/sio/sio.h)  
</details>

<details>
<summary>smb</summary>  

* [i801.c](src/hal/smb/i801.c)  
* [nct5655.c](src/hal/smb/nct5655.c)  
* [nct5655_gpio.c](src/hal/smb/nct5655_gpio.c)  
* [pca9555.c](src/hal/smb/pca9555.c)  
* [pca9555_gpio.c](src/hal/smb/pca9555_gpio.c)  
* [smb.h](src/hal/smb/smb.h)  
* [zhaoxin.c](src/hal/smb/zhaoxin.c)  
</details>

</details>

<details>
<summary>.local</summary>

* [package.sh](.local/package.sh)  
* [release.sh](.local/release.sh)  
</details>

<details>
<summary>scripts</summary>  

* [config.sh](scripts/config.sh)  
</details>  

