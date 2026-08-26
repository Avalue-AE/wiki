# Android APK installation for OFT PC

Here is the process to install apk file to Android in Windows environment.  

1. Please download Oracle JDK from [here ↗](https://www.oracle.com/java/technologies/downloads/#java8) and install it.
   ![jdk](images/OFT-APK/jdk.png)  
2. Please download Android SDK from [here ↗](https://developer.android.com/studio) and install it.  
   ![android_sdk](images/OFT-APK/android_sdk.png)  
3. Once you finish Android SDK installation, it will run Android SDK manager automatically. Install packages in Android SDK manager.  
   ![android_sdk_tools_setup_complete](images/OFT-APK/android_sdk_tools_setup_complete.png)  
   ![android_sdk_manager](images/OFT-APK/android_sdk_manager.png)  
   ![android_sdk_manager_2](images/OFT-APK/android_sdk_manager_2.png)  
   ![android_sdk_manager_3](images/OFT-APK/android_sdk_manager_3.png)  
   > [!NOTE]
   > If you faced difficulty fetching package from google, check the box below.  
   >![android_sdk_manager-1](images/OFT-APK/android_sdk_manager-1.png)  
   >![android_sdk_manager-2](images/OFT-APK/android_sdk_manager-2.png)  
4. Please refer to this [link](https://01.org/zh/android-ia/downloads/intel-platform-flash-tool-lite?langredirect=1) to install `Intel® Android* USB Drivers`.  
5. Now we have to run adb.exe to connect with Android. Normally you will find it in `C:\Program Fils <x86>\Android\android-sdk\platform-tools`.  
6. You will have to put apk file in platform-tools folder. Download Android file manager from [here]() and place it in the same folder of `adb.exe`.  
7. Please remember to enable Android developer mode by click `Setting⇒About tablet ⇒ Build number` several times in Android.  
8. Please enable USB debug mode by click `Setting⇒Developer options⇒USB debugging`  
9. Run command below in command prompt.  
    ```bash
    adb install xxx.apk
    ```  
    ![adb_install](images/OFT-APK/adb_install.png)  
10. Once you finish Android file manager installation, you can install any apk file by USB disk on OFT-XXW01.  
