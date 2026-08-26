# How do I create and add RSA key to Avalue GIT server?

1. Create RSA key of your Linux development platform.

    For example, my Linux development platform is Ubuntu 14.04 x64 system. Here is the process to generate RSA key on it.

    Use command below to generate RSA Key :  
    ```
    #ssh-keygen -t rsa
    ```

    You can find “id_rsa.pub” in path below. Please use text editor to read content and copy all of them.  
    ```
    #/home/username/.ssh/
    ```

    ![gen_rsa_key](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/gen_rsa_key.jpg)  
    ![rsa_key_copy](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/rsa_key_copy.jpg)  

2. Get access of Avalue GIT server (http://aes.avalue.com.tw). Please contact with Avalue sales people to get user name & password to access it.
    ![git_server_login](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/git_server_login.jpg)  

3. Once you log into Avalue GIT server, please click on “Profile Settings”
    ![git_profile_setting](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/git_profile_settings.jpg)  

    Then click on "SSH Keys"
    ![ssh_keys_aes](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/ssh_keys_aes.jpg)  

    Clink "Add SSH Key"
    ![ssh_keys_add](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/ssh_keys_add.jpg)  

    Just paste the content of id_rsa.pub in key area and press “Add key” button.
    ![ssh_keys_add2](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/ssh_keys_add2.jpg)  

    Once you finish it, your RSA key of development platform is in Avalue GIT server already. You will have access right to Avalue git server and you can start to download source code from it.
    ![ssh_keys_add3](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/ssh_keys_add3.jpg)  

4. Try to download source code right now. Go to main page of Avalue git server. Select one of the project on the right.  
    ![git_select_project](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/git_select_project.jpg)  

    Copy the git link. You will also need branch version information to download source code (for example : 3.0.35-4.0.0)  
    ![git_link_branch](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/git_link_branch.jpg)  

    In command prompt of your Linux development platform, please key in command below to download source code :
    ```
    #git clone gitlab@aes.avalue.com.tw:REV-SA01/REV-SA01_Kernel.git -b 3.0.35-4.0.0
    ```  

    ![git_download](../images/FAQ/How-do-I-create-and-add-RSA-key-to-Avalue-GIT-server/git_download.jpg)  