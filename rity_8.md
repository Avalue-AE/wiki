## Build and install Android image for RITY8R1

Here you can find instruction to setup development environment for
Android source code for RITY8R1 and the way to install it on eMMC. With
this guideline, user will be able to setup the system easily and test
all the functions with the system.  

## Setup Build Environment

Please following command below to install Oracle JDK6.0 on Ubuntu 12.04
or 14.04  

    #sudo apt-get install python-software-properties
    #sudo add-apt-repository ppa:webupd8team/java
    #sudo apt-get update
    #sudo apt-get install oracle-java6-installer
    #sudo update-alternatives --config java

Please refer to hyperlink below to setup development environment  
[Initializing a Build
Environment](https://source.android.com/source/initializing.html)

## Generating RSA Keys

Use command below to generate RSA Key :  

    #ssh-keygen -t rsa

You can find “**id_rsa.pub**” in path below. Please send it to us by
email to get access right of Avalue GIT server.

    #/home/username/.ssh/

If you had done this before for your Ubuntu development platform,
there’s no necessary to do it again.  

## Download Source code and cross compiler tool from Avalue git server

    #git clone giter@aes.avalue.com.tw:Android.git -b POS-4.4.2

## Compile Android Source code

Please following instruction below to compile Android source code  

    #cd Android
    #./run.sh -j4

You can find all image files in path
**Android/out/target/product/smarc/**  

| Image File     | Description                      |
|----------------|----------------------------------|
| boot.img       | kernel image file                |
| recovery.img   | recovery image file              |
| system.img     | system image file                |
| u-boot-6q.bin  | bootloader for RITY8R1 Quad core |
| u-boot-6dl.bin | bootloader for RITY8R1 Dual lite |

Please copy all of them to path **Android-MfgTools\Image\smarc\android**
of MfgTool folder.  

## Install Android image into eMMC

Download MfgTool for Android from Hyperlink below  
[MfgTool for
Android](ftp://dennis:8710@ftp.avalue.com.tw/dennis/IMX6/RITY_8/RITY_POS-Android-MfgTools.rar)

1\. Set JBTSL1 on RITY8R1 as below to serial download mode  
![acp-imx6pos_jbtsl1.png](/acp-imx6pos_jbtsl1.png)

2\. Use mini-USB cable to connect JMUSB1 on RITY8R1 to Windows 7
system.  
3. Run “MFG-Helper.exe” on the path
(~\RITY_POS-Android-MfgTools\Mfg-POS)  
3-1. Please select as below for Dual lite then click “Run MFG-Tools”  
<img src="/solo.jpg" data-query="?nolink" alt="solo.jpg" />  
  
3-2. Please select as below for Quad core then click “Run MFG-Tools”  
<img src="/pos_mfg_quad.jpg" data-query="?nolink"
alt="pos_mfg_quad.jpg" />  
  
3-3. Press “Start” to flash image files  
![mfgtool_start.png](/mfgtool_start.png)  
4. It will show “Done” after flashing is finish, then click “Stop” and
“Exit” to close the screen.  
![mfgtool_finish.png](/mfgtool_finish.png)  
5. Set SW1 as below to boot from eMMC  
<img src="/pin_1_on.jpg" data-query="?direct" alt="pin_1_on.jpg" />

6\. Restart the system then boot in Android  

## Setting for different display (LDB, HDMI, LDB+HDMI)

For Android, please move the directory to “~/
kernel_imx/arch/arm/mach-mx6/board-mx6_pos.c”, you can refer the
contents below to revise it for suitable display.

1.HDMI

           {
            .disp_dev = "hdmi",
            .interface_pix_fmt = IPU_PIX_FMT_RGB24,
            .mode_str = "1920x1080M@60",
            .default_bpp = 32,
            .int_clk = false,
            .late_init = false,
            },

            mx6q_init_audio();
            smarc_fb_init();
    //      set_smarc_lvds();
    //      imx6q_add_lcdif(&lcdif_data);
    //      imx6q_add_ldb(&ldb_data);
            set_smarc_hdmi();
            imx6q_add_vpu();
            imx_add_viv_gpu(&imx6_gpu_data, &imx6q_gpu_pdata);
            imx6q_add_v4l2_output(0);

            set_smarc_gpio();
            mx6q_smarc_init_uart();
            set_smarc_sdio();
            smarc_can_init();

        static struct fsl_mxc_hdmi_core_platform_data hdmi_core_data = {
        .ipu_id = 0,
        .disp_id = 0,
        };

2.LDB(LVDS)  

           {
            .disp_dev = "ldb",
            .interface_pix_fmt = IPU_PIX_FMT_RGB666,
            .mode_str = "SVGA",
            .default_bpp = 32,
            .int_clk = false,
            .late_init = false,
            },

    void __init smarc_board_init(void)
    {
            mx6q_init_audio();
            smarc_fb_init();
            set_smarc_lvds();
    //      imx6q_add_lcdif(&lcdif_data);
            imx6q_add_ldb(&ldb_data);
    //      set_smarc_hdmi();
            imx6q_add_vpu();
            imx_add_viv_gpu(&imx6_gpu_data, &imx6q_gpu_pdata);
            imx6q_add_v4l2_output(0);

            set_smarc_gpio();
            mx6q_smarc_init_uart();
            set_smarc_sdio();
            smarc_can_init();

    static struct fsl_mxc_ldb_platform_data ldb_data = {
            .ipu_id                 = 0,
            .disp_id                = 0,
            .ext_ref                = 1,
            .mode                   = LDB_SEP0,
            .sec_ipu_id             = 0,
            .sec_disp_id    = 1,
    };

3\. LDB+HDMI  

    static struct ipuv3_fb_platform_data smarc_fb_data[] = {

            {
            .disp_dev = "ldb",
            .interface_pix_fmt = IPU_PIX_FMT_RGB666,
            .mode_str = "SVGA",
            .default_bpp = 32,
            .int_clk = false,
            .late_init = false,
            },

             {
            .disp_dev = "hdmi",
            .interface_pix_fmt = IPU_PIX_FMT_RGB24,
            .mode_str = "1920x1080M@60",
            .default_bpp = 32,
            .int_clk = false,
            .late_init = false,
            },

    void __init smarc_board_init(void)
    {
            mx6q_init_audio();
            smarc_fb_init();
            set_smarc_lvds();
    //      imx6q_add_lcdif(&lcdif_data);
            imx6q_add_ldb(&ldb_data);
            set_smarc_hdmi();
            imx6q_add_vpu();
            imx_add_viv_gpu(&imx6_gpu_data, &imx6q_gpu_pdata);
            imx6q_add_v4l2_output(0);

            set_smarc_gpio();
            mx6q_smarc_init_uart();
            set_smarc_sdio();
            smarc_can_init();

    static struct fsl_mxc_ldb_platform_data ldb_data = {
            .ipu_id                 = 0,
            .disp_id                = 0,
            .ext_ref                = 1,
            .mode                   = LDB_SEP0,
            .sec_ipu_id             = 0,
            .sec_disp_id    = 1,
    };

    static struct fsl_mxc_hdmi_core_platform_data hdmi_core_data = {
        .ipu_id = 1,
        .disp_id = 0,
    };
