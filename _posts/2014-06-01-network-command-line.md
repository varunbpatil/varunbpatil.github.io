---
layout: post
title: "Connecting to wired/wireless networks via command line"
---

If you use a window manager like DWM, i3, Xmonad, etc, you are more than likely to get rid of the usual panel/system tray you would normally find in xfwm, lxde, etc. So here is how you can use the command line to connect to wired/wireless networks in Linux.

NOTE: The following tutorial uses the 'ip' command instead of the ifconfig command where possible.

#### Pre-requisites
If you want to connect to wireless networks secured with WPA, you will need to install wpasupplicant.

    $ sudo apt-get install wpasupplicant

If you want to connect to a PPP network (Ex: Reliance netconnect+ broadband), you will need to install wvdial.

    $ sudo apt-get install wvdial

#### Connecting to a wired network

Assuming your wired network interface is named eth0,

    $ sudo ip link set dev eth0 up

    $ sudo dhclient eth0

#### Connecting to a wireless (WEP) network

Assuming the essid of the wireless network you are trying to connect to is XXXXXXX and the hex key is YYYYYYY, and the your wireless network interface is named wlan0,

    $ sudo ip link set dev wlan0 up

    $ sudo iwconfig wlan0 essid "XXXXXXX"

    $ sudo iwconfig wlan0 key YYYYYYY

    $ sudo dhclient wlan0

#### Connecting to a wireless (WPA) network

Assuming the essid of the wireless network you are trying to connect to is XXXXXXX and the hex key is YYYYYYY, and your wireless network interface is named wlan0, first create a config file under /etc as shown below.

    $ sudo touch /etc/wpa_supplicant_xxxx.conf

NOTE: you can use any file name above. One file required per wireless network that you want to connect to.

Enter the following contents into the above file and save it (root permission required).

    ap_scan=1
    ctrl_interface=/var/run/wpa_supplicant

    network={
        ssid="XXXXXXX"
        scan_ssid=0
        proto=WPA
        key_mgmt=WPA-PSK
        psk="YYYYYYY"
        pairwise=TKIP
        group=TKIP
    }

Now, to connect to the above wireless network,

    $ sudo ip link set dev wlan0 up

    $ sudo wpa_supplicant -Dwext -iwlan0 -c/etc/wpa_supplicant_xxxx.conf -B

    $ sudo dhclient wlan0

#### BONUS : Connecting to wireless (PEAP) network

PEAP encrypted networks are usually used in corporate environments. Here's how you can connect to it.

Assuming the essid of the wireless network you are trying to connect to is XXXXXXX and the hex key is YYYYYYY, and your wireless network interface is named wlan0, first create a config file under /etc as shown below.

    $ sudo touch /etc/wpa_supplicant_xxxx.conf

NOTE: you can use any file name above. One file required per wireless network that you want to connect to.

Enter the following contents into the above file and save it (root permission required).

    network={
        ssid="XXXXXXX"
        key_mgmt=WPA-EAP
        eap=PEAP
        identity="username@company.com"
        password="YYYYYYY"
        pairwise=CCMP TKIP
        group=CCMP TKIP
        phase2="auth=MSCHAPV2"
    }

Now, to connect to the above wireless network,

    $ sudo ip link set dev wlan0 up

    $ sudo wpa_supplicant -Dwext -iwlan0 -c/etc/wpa_supplicant_xxxx.conf -B

    $ sudo dhclient wlan0

#### BONUS : Connecting to a PPP network (Mobile Broadband)

First, create the following file under /etc

    $ sudo touch /etc/wvdial.conf

Enter the following contents into the above file (for reliance netconnect+ broadband)

    [Dialer Defaults]
    Phone =
    Username =
    Password =
    New PPPD = yes

    [Dialer NAME_OF_YOUR_NETWORK]
    Phone = #777
    Username = <username>
    Password = <password>
    Stupid Mode = 1
    Idle Seconds = 0
    Dial Attempts = 0
    Modem = /dev/ttyUSB0

Now, to connect to the mobile broadband network above,

    $ sudo wvdial NAME_OF_YOUR_NETWORK

#### BONUS : Listing available wireless networks

To list the available wireless networks (i.e, their essid's) much like Network Manager does,

    $ sudo ip link set dev wlan0 up

    $ sudo iwlist wlan0 scan | grep ESSID | awk -F\" '{print $2}'
