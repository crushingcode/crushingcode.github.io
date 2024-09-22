---
title: "Life without wires : ADB over WiFi"
date: 2015-07-09
authors:
  - name: Nishant Srivastava
    link: /about/
type: blog
---

Tired of being tied to your laptop/desktop while debugging your android apps ?
Well let me break it to you – You are NOT the FIRST person bugged by this issues.

Its a common practice to tether your device via a USB cable to the host machine and debug android apps.Well here is something for you that is going to set you free. Yes literally. You can run adb over WiFi (period)

Yes , you read that right! Thats the secret solution(…ok not secret.. :p ) and setting it up is a piece of cake :P
Most people ask me why another post on this, well if you googled it you would come across a lot of information regarding the same but most of it is outdated or you would be using hit-and-trial method to get it working. I did some research on my own and found a way to get it working in the below steps.

I will walk you through the process of doing so in the most easiest way.
All you need is a USB cable (for the initial setup) and have your laptop/desktop and the devices connected to the same network (work on 99% cases)

1. Connect your mobile device via USB and make sure usb debugging is on (you can do that via the developer options in your device).
   Also connect to your Wifi.

1. Open up the Terminal , provided you have the adb set in your PATH, type the following

   ```sh
   adb devices
   ```

   this would list your device as connected over the USB

1. To enable the wifi-debug-mode

   ```sh
   adb tcpip 5555
   ```

1. Get your DEVICE-IP-ADDRESS

   ```sh
   adb shell netcfg | grep 'wlan0'
   ```

   you will get something like this

   ```sh
   wlan0 UP 192.168.2.23/24 0x00001043 cc:c3:ea:ef:12:11
   ```

   where 192.168.2.23 is your DEVICE-IP-ADDRESS

   **OR**

   you can navigate to **Settings > About phone > Status** on your device, to view the IP address of your phone.

1. **IMPORTANT : Remove USB cable**

1. Connect your device by typing in the below in the terminal

   ```sh
   adb connect DEVICE-IP-ADDRESS:5555
   ```

1. To confirm the connection just made, type in the terminal

   ```sh
   adb devices
   ```

   this should list your device as connected over the particular DEVICE-IP-ADDRESS

   And you are done. Run/Debug your apps from your IDE in wireless mode. Let the magic of wire-free-life begin.

1. Did I mention that to switch back to USB mode you simply type in the below command in terminal

   ```sh
   adb usb
   ```

## Things to Note

- If you move into a different workspace and change WiFi networks, you simply repeat steps 5 and 6 . The steps 1 to 5 are used to set your device into wifi-debug mode.

- The device will exit the wifi-debug mode when it restarts. So if your device restarts unfortunately, you will have to start over (from steps 1 to 6). So if you keep an eye on your battery and do not restart your device, you can live without cables for weeks.

**Reference:**
[Info about ADB](http://developer.android.com/tools/help/adb.html)
