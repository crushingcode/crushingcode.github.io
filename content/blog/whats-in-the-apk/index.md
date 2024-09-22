---
title: "Whats in the APK?"
date: 2016-09-24
authors:
  - name: Nishant Srivastava
    link: /about/
type: blog
---

![Banner](header.jpg)

<!--more-->

If I give you the code of an android app and ask you to provide me information regarding the android **app** like `minSdkVersion`, `targetSdkVersion`, permissions, configurations, almost anyone who knows how to code an android app would provide it to me in a few minutes. But what if I gave you an android **apk** file and then ask you to answer for the same 🤔 Its tricky if you try to think at the very first instance.

I actually ran into such a situation and even though I had known `aapt` tool for a long time, it didnot hit my head the very first instance when I had to get the permissions declared inside the `apk`. It was clear I needed to brush up the concepts and follow an efficient approach. This blog post will explain how to do so. Also helpful when you are trying to reverse lookup contents of any other app 🤓

_**Ok, the most common way to approach this problem has to be this one**_

Going with the definition of an **[APK](https://en.wikipedia.org/wiki/Android_application_package)**

> **Android application package (APK)** is the package file format used by the Android operating system for distribution and installation of mobile apps and middleware.
>
> ...**APK** files are a type of archive file, specifically in **zip** format packages based on the JAR file format, with .apk as the filename extension.

![header](apk.jpg)

..hmm so its basically a _**ZIP**_ format, so what I can do is rename the extension from **.apk** to **.zip** and I should be able extract the contents.

![header](rename.jpg)

![header](zip.jpg)

Cool, so we now see what the zip file contain and they are all available for inspection.

![header](contents.jpg)

Well at this point you would think that you have got access to all files so you can give me all the information right away. Well not so quick Mr.AndroidDev 😬

Go ahead try and open up the `AndroidManifest.xml` in some text editor to check out its content. This is what you would get

![header](androidmanifest.jpg)

..what it basically means is that the `AndroidManifest.xml` isn't in human readable format anymore. So your chances of reading basic information regarding the apk from the `AndroidManifest.xml` goes down the drain 😞

....

...

..

..Not really 😋 There are tools to analyze the Android APK and there is one which has been there since the very beginning.

> I think its known to all the experinced devs but I am pretty sure a lot of budding as well as seasoned Android Devs have not even heard about it.

The tool thats available as part of the Android Build Tool is

#### **`aapt`** - Android Asset Packaging Tool

> This tool can be used to list, add and remove files in an APK file, package resources, crunching PNG files, etc.

First of all, where exactly is this located 🤔

Good question, its available as part of build tools in your android sdk.

```
<path_to_android_sdk>/build-tools/<build_tool_version_such_as_24.0.2>/aapt
```

..ok so what can it actually do ? From the `man` pages of the tool itself

- `aapt list` - Listing contents of a ZIP, JAR or APK file.
- `aapt dump` - Dumping specific information from an APK file.
- `aapt package` - Packaging Android resources.
- `aapt remove` - Removing files from a ZIP, JAR or APK file.
- `aapt add` - Adding files to a ZIP, JAR or APK file.
- `aapt crunch` - Crunching PNG files.

We are interested in `aapt list` and `aapt dump` specifically as these are what will help us provide `apk` information.

Lets find information that we are looking for directly from the `apk` by running the `aapt` tool on it.

<hr>
##### Get base information of the apk
```bash
aapt dump badging app-debug.apk 
```

##### > Result

```bash
package: name='com.example.application' versionCode='1' versionName='1.0' platformBuildVersionName=''
sdkVersion:'16'
targetSdkVersion:'24'
uses-permission: name='android.permission.WRITE_EXTERNAL_STORAGE'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.RECORD_AUDIO'
uses-permission: name='android.permission.READ_EXTERNAL_STORAGE'
application-label-af:'Example'
application-label-am:'Example'
application-label-ar:'Example'
..
application-label-zu:'Example'
application-icon-160:'res/mipmap-mdpi-v4/ic_launcher.png'
application-icon-240:'res/mipmap-hdpi-v4/ic_launcher.png'
application-icon-320:'res/mipmap-xhdpi-v4/ic_launcher.png'
application-icon-480:'res/mipmap-xxhdpi-v4/ic_launcher.png'
application-icon-640:'res/mipmap-xxxhdpi-v4/ic_launcher.png'
application: label='Example' icon='res/mipmap-mdpi-v4/ic_launcher.png'
application-debuggable
launchable-activity: name='com.example.application.MainActivity'  label='' icon=''
feature-group: label=''
  uses-feature: name='android.hardware.camera'
  uses-feature-not-required: name='android.hardware.camera.autofocus'
  uses-feature-not-required: name='android.hardware.camera.front'
  uses-feature-not-required: name='android.hardware.microphone'
  uses-feature: name='android.hardware.faketouch'
  uses-implied-feature: name='android.hardware.faketouch' reason='default feature for all apps'
main
other-activities
supports-screens: 'small' 'normal' 'large' 'xlarge'
supports-any-density: 'true'
locales: 'af' 'am' 'ar' 'az-AZ' 'be-BY' 'bg' 'bn-BD' 'bs-BA' 'ca' 'cs' 'da' 'de' 'el' 'en-AU' 'en-GB' 'en-IN' 'es' 'es-US' 'et-EE' 'eu-ES' 'fa' 'fi' 'fr' 'fr-CA' 'gl-ES' 'gu-IN' 'hi' 'hr' 'hu' 'hy-AM' 'in' 'is-IS' 'it' 'iw' 'ja' 'ka-GE' 'kk-KZ' 'km-KH' 'kn-IN' 'ko' 'ky-KG' 'lo-LA' 'lt' 'lv' 'mk-MK' 'ml-IN' 'mn-MN' 'mr-IN' 'ms-MY' 'my-MM' 'nb' 'ne-NP' 'nl' 'pa-IN' 'pl' 'pt' 'pt-BR' 'pt-PT' 'ro' 'ru' 'si-LK' 'sk' 'sl' 'sq-AL' 'sr' 'sr-Latn' 'sv' 'sw' 'ta-IN' 'te-IN' 'th' 'tl' 'tr' 'uk' 'ur-PK' 'uz-UZ' 'vi' 'zh-CN' 'zh-HK' 'zh-TW' 'zu'
densities: '160' '240' '320' '480' '640'
```

<hr>
##### Get list of permissions declared in the AndroidManifest of the apk
```bash
aapt dump permissions app-debug.apk
```

##### > Result

```bash
package: com.example.application
uses-permission: name='android.permission.WRITE_EXTERNAL_STORAGE'
uses-permission: name='android.permission.CAMERA'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.RECORD_AUDIO'
uses-permission: name='android.permission.READ_EXTERNAL_STORAGE'
```

<hr>
##### Get list of configurations for the apk
```bash
aapt dump configurations app-debug.apk
```

##### > Result

```bash
large-v4
xlarge-v4
night-v8
v11
v12
v13
w820dp-v13
h720dp-v13
sw600dp-v13
v14
v17
v18
v21
ldltr-v21
v22
v23
port
land
mdpi-v4
ldrtl-mdpi-v17
hdpi-v4
ldrtl-hdpi-v17
xhdpi-v4
ldrtl-xhdpi-v17
xxhdpi-v4
ldrtl-xxhdpi-v17
xxxhdpi-v4
ldrtl-xxxhdpi-v17
ca
af
..
sr
b+sr+Latn
...
sv
iw
sw
bs-rBA
fr-rCA
lo-rLA
...
kk-rKZ
uz-rUZ
```

..also try out these

```
# Print the resource table from the APK.
aapt dump resources app-debug.apk

# Print the compiled xmls in the given assets.
aapt dump xmltree app-debug.apk

# Print the strings of the given compiled xml assets.
aapt dump xmlstrings app-debug.apk

# List contents of Zip-compatible archive.
aapt list -v -a  app-debug.apk
```

.. as you can see you can easily get the information without even going through the process of unzipping the `apk`, but by using the `aapt` tool directly on the `apk`.

There is more that you can do , taking more info from the `man` pages of the `aapt` tool

```bash
aapt r[emove] [-v] file.{zip,jar,apk} file1 [file2 ...]
  Delete specified files from Zip-compatible archive.

aapt a[dd] [-v] file.{zip,jar,apk} file1 [file2 ...]
  Add specified files to Zip-compatible archive.

aapt c[runch] [-v] -S resource-sources ... -C output-folder ...
  Do PNG preprocessing and store the results in output folder.
```

..I will let you explore these on your own 🙂

Comment/Suggestions always welcome.

[Reference Link](http://elinux.org/Android_aapt)

> Got featured in [AndroidWeekly Issue 224](http://androidweekly.net/issues/issue-224), thank you for the love

If you would like to get more of such android tips and tricks, just hop onto my **[Android Tips & Tricks](https://github.com/nisrulz/android-tips-tricks)** github repository. I keep updating it constantly.

Keep on crushing code!🤓 😁
