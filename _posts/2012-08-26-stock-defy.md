---
layout: post
title: "How to go back to stock rom on Motorola Defy"
---
I have always loved custom ROM's like the Cyanogenmod and MIUI. I like to be on the bleeding edge. Once I got my hands at the ICS and JB rom's by Cyanogenmod, I never thought I'd look back. I never thought I'd have to ever again go back to stock Motorola defy Froyo ROM. But, I was wrong. Recently, on one of my regular Cyanogenmod JB nightly(Quarx's build) updates, my phone restarted in the middle of the update and that was it... GONE !!!. The phone did not boot and when I tried clearing the cache, I got some weird errors. I couldn't get access to the SDcard on the phone... Even wiping data and clearing dalvik cache did not help... I really thought I had bricked my phone, but then after some frantic google searches on the XDA developers forum, I learnt that bricking a motorola defy is really hard, thanks to the locked bootloader on the motorola defy.

Then I heard several such cache errors being reported and several solution to the same, the most recommended of which was to go back to stock ROM by using a tool called RSDLite and without a doubt, it worked flawlessly and the procedure couldn't have been easier. Here are all the steps you need to go back to stock ROM on motorola defy(if you have had any cache errors and unable to boot up). I have even given the steps to once again flash your favourite custom ROM after re-rooting your defy, if you are one of those people who cannot live without the custom ROM, but only need the stock ROM as a way to recover from the horrifying errors.

#### What you will need before you start

* Download __RSDLite__ from [here](http://forum.xda-developers.com/attachment.php?attachmentid=835334&d=1325246927).

* Make sure your computer can recognize your defy... make sure you have the __motorola defy drivers__ installed on your windows system. You can download the drivers [here](http://forum.xda-developers.com/attachment.php?attachmentid=525694&d=1298502477).

* Download the correct __".sbf" file__ for your motorola defy from [here](http://sbf.droid-developers.org/phone.php?device=27). This is the most overwhelming aspect of it all, with so many .sbf file versions out there for the taking and warnings everywhere regarding the consequences of flashing a wrong sbf file. At this point it pays to remember which version of Android your phone had when you bought it and whether it came loaded with Motoblur or not. I had bought my Motorola defy in India and had come with Froyo and without motoblur... So the sbf file I downloaded is [here](http://sbf.droid-developers.org/download.php?device=27&file=577). This is a gzip archive. You will need to extract it to get the .sbf file.

* If you want to re-root your phone and flash a Custom ROM again!!!, you will need [SuperOneClick](http://download.cnet.com/SuperOneClick/3000-2094_4-75447027.html) and [SndInitDefy](http://www.4shared.com/file/PbVxYsPx/sndinitdefy__23_.html).

#### Procedure to go back to stock on Motorola defy

* __Power off__ your phone.

* __Press and hold the volume down__ button while booting. You will see a triangle with an exclamation mark on the screen.

* Now press both the volume up and volume down buttons __simultaneously__.

* At the screen that comes up, __wipe cache and wipe data__ and factory reset. Don't worry if you get cache errors here.

* __Reboot__ the phone once again, this time while keeping the __volume up button depressed__.

* You will enter a screen with white text on a black background, saying something like, USB connection or something.

* Now connect your phone to the computer via the USB cable, and you should see a change in the text displayed on the phone... something like USB connected.

* This means that your phone has been detected by the computer and you have the right motorola drivers for your phone.

* Now __launch RSDLite__ (you will have to install it first on your computer). There should be one line in the progress display area that shows some info about the current status of your phone. If this line is not there, it means your device is not detected by the computer. Try reinstalling the defy drivers.

* Now it is time to __select the .sbf file__ that you downloaded earlier. To do this, click on the "..." button in RSDLite and select the .sbf file from your computer's filesystem.

* Now __click on start__. The process of flashing the stock ROM will begin. The progress display area will show the percentage completion of the process.

* Sit back and relax. Your phone will be alright afterall. Wait till it says "executed : 100%", but __do not disconnect__ the phone or exit the program.

* Now the phone will automatically reboot and continue the process of flashing.

* Wait till the whole process completes and you see a __"Finished" and "Pass"__ in the results area.

* That was it... Congratulations!!! You now have stock defy ROM on your phone. Now you can heave a sigh of relief knowing that you have not bricked your phone.

#### Re-rooting and re-installing your favorite custom ROM

This is for all those impatient people who want to get back to their favorite Custom ROM and only needed the stock ROM flashing to get rid of those terrifying cache errors. As usual, it is very simple, so read on...

* The program I use to root my Motorola defy is __SuperOneClick__, which you would have downloaded from the pre-requisites section above. Make sure you have __enabled USB Debugging on your phone__ after you have flashed the Stock Motorola defy ROM following the steps above. Launch the SuperOneClick program, connect your phone to the computer via USB and __click on the "ROOT"__ button at the top left corner of the SuperOneClick program. The rooting process will start. At some point, it will prompt you whether you would like to install BusyBox on your phone. Click on YES. The phone will reboot a couple of times during the process... Nothing to worry there. At the end of the rooting procedure you will be prompted whether you would like to test the root... Click on YES. That's it... Your phone is rooted. You can close the SuperOneClick program.

* Now that you have root on your phone, you have to __install 2ndinit and recovery__ which will allow you to flash any custom ROM, that you so loved before you were brought down to your knees by the cache errors!!!.

* Transfer the SndInitDefy.apk file that you downloaded earlier to your phone's sdcard and install it like any other android app using the native file manager or any other file manager like ASTRO or ES File Explorer from the android market. To do this, however you will have to __enable installing 3rd party apps__. This option is available in the Developer's section in the settings screen. If you are feeling very geeky, you can as well use ADB to install the app with the command "adb install SndInitDefy.apk". Now that you have installed the SndInitDefy app, launch it from your phone. You will see a text in red at the top saying that 2ndinit menu is not installed. So, go ahead and click the button in the middle of the screen to install 2ndinit menu. After that you should see a text in green at the top of the screen saying that 2ndinit menu has been installed. That's it... You can now boot into recovery and flash your favorite Custom ROM just like you have done a gazillion times before :)
