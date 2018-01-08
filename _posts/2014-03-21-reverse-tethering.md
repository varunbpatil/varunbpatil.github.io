---
layout: post
title: "Android reverse USB tethering"
---

We all know what USB tethering is in android -- enabling internet connectivity on your PC via your phone. Reverse USB tethering is... well... exactly the reverse. Enabling internet connectivity on your phone via your PC. The following tutorial shows you how to set up reverse USB tethering on Linux. Also included is a shell script to automate the setup on Linux.

#### How to set up reverse USB tethering on Linux

* Connect your android phone to your PC via USB and enable USB tethering from the settings on your phone.

* Find out the new network interface that was created on your PC with the following command.

        $ ifconfig  # on your PC

  In my case, the new network interface was __usb0__.

* Enter the following commands on your Linux PC.

        $ sudo ifconfig usb0 10.42.0.1 netmask 255.255.255.0

        $ echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

        $ sudo iptables -t nat -F

        $ sudo iptables -t nat -A POSTROUTING -j MASQUERADE

* Enter the following commands on your android phone. You can either use terminal emulator or enter the command through [ADB](http://localhost:4000/2012/06/18/adb/) like below.

        $ adb shell busybox ifconfig

  Note down the network interface on your android phone. Mine was __rndis0__.

        $ adb shell ifconfig rndis0 10.42.0.2 netmask 255.255.255.0

        $ adb shell route add default gw 10.42.0.1 dev rndis0

  Verify internet connectivity on your phone with

        $ adb shell ping 8.8.8.8


That's it. You now have internet connectivity on your android phone.

I have written a small [shell script](http://pastebin.com/raw.php?i=wqVnx9Vw) to automate the above process on Linux. You can get it with the following command.

    $ wget http://pastebin.com/raw.php?i=wqVnx9Vw -O rev_usb_tether.sh

Run it on your PC with the following commands.

    $ chmod +x rev_usb_tether.sh

    $ ./rev_usb_tether.sh


__DISCLAIMER :__ Some apps like gmail, play store still won't recognize the internet connection.
