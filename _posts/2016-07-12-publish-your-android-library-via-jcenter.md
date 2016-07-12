---
layout: post
title:  "Guide to publishing your Android Library via Jcenter/Bintray"
description: Guide to publishing your Android Library via Jcenter/Bintray
permalink: /publish-your-android-library-via-jcenter/
date: 2016-07-12 02:20:36 +0530
author: "Nishant"
---

Developers are a different kind of people altogether. __They tend to be lazy but strive to be super efficient at the same time__.
A lot of this can be seen in the Android world where a certain library pops up everyday to solve a specific problem or  to make the complex processes simpler.

I have a certain knack for re-using code blocks just to avoid repeative tasks and to facilitate this I usually end up converting those codeblocks into an android library.

> But what if I wanted to share my android library with the world?

Well in a nutshell the steps to follow would be as below :

+ First of all I need to open source the andorid library, which should be easy as you can push it to [Github](https://github.com/) or any other public git repository.
+ Next I need to push the android library as a maven artifact (aar/jar with a POM) to all of the or one of the below central repositories

	+ [JCenter/Bintray](https://bintray.com/) 
	+ [Maven Central](https://search.maven.org/)
	+ [Jitpack](https://www.jitpack.io/)

We will walkthrough the process of publishing to each if these central repositories in the upcoming posts of this series. 

For now lets lookup the steps to publish your android library to JCenter/Bintray.


##### Creating your Android "Awesome" Library
> You can skip to the next part if you already have this built

+ Create an Android project or open an existing one in [Android Studio](https://en.wikipedia.org/wiki/Android_Studio)
+ Init the project with git and also create a repo on Github for the same. Each step here onwards represent a commit and should be pushed to github.
+ Create and add a new module and choose `Android Library`.
   
   > Goto `File>New>New Module..` and select `Android Library`.
   
   <amp-img width="400" height="100" layout="responsive" src="/assets/images/posts/uploadtojcenter/newmodule.jpeg"></amp-img>
   
   <amp-img width="400" height="255" layout="responsive" src="/assets/images/posts/uploadtojcenter/newlib.jpeg"></amp-img>
   
   <amp-img width="400" height="255" layout="responsive" src="/assets/images/posts/uploadtojcenter/newlibinfo.jpeg"></amp-img>

+ Implement your library code inside the library module you created in the last step.
+ Next add the library module as a dependency to the app module.

   > 1. Goto `File>Project Structure..`
   > 1. Select `app` module in the sidebar
   > 1. Select the `Dependencies` tab
   > 1. At the bottom is a `+` icon, click that and select `Module dependency` and select your `library` module.
   > 1. Press `apply` or `ok`.
   
   <amp-img width="200" height="30" layout="responsive" src="/assets/images/posts/uploadtojcenter/project.jpeg"></amp-img>
   
   <amp-img width="400" height="320" layout="responsive" src="/assets/images/posts/uploadtojcenter/prjstruct.jpeg"></amp-img>
   
   <amp-img width="320" height="80" layout="responsive" src="/assets/images/posts/uploadtojcenter/addmodule.jpeg"></amp-img>
   
##### Publishing your Android "Awesome" Library

+ Once project is synced, add the required plugins to classpath in `build.gradle` file at root project level, as shown below

```gradle
 dependencies {
    classpath 'com.android.tools.build:gradle:2.1.2'
    ..
    ..
    // Required plugins added to classpath to facilitate pushing to Jcenter/Bintray
    classpath 'com.jfrog.bintray.gradle:gradle-bintray-plugin:1.4'
    classpath 'com.github.dcendents:android-maven-gradle-plugin:1.3'
    ..
   }
```
+ Next, apply the `bintray` and `install` plugins at the bottom of build.gradle file at library module level. Also add the ext variable with required information as shown below

```gradle
 apply plugin: 'com.android.library'
 
 ext {
   bintrayRepo = 'maven'
   bintrayName = 'awesomelib'   // Has to be same as your library module name
 
   publishedGroupId = 'com.github.nisrulz'
   libraryName = 'AwesomeLib'
   artifact = 'awesomelib'     // Has to be same as your library module name
 
   libraryDescription = 'Android Library to make any text into Toast with Awesome prepended to the text'
 
   // Your github repo link
   siteUrl = 'https://github.com/nisrulz/UploadToBintray'
   gitUrl = 'https://github.com/nisrulz/UploadToBintray.git'
 
   libraryVersion = '1.0'
 
   developerId = 'nisrulz'
   developerName = 'Nishant Srivastava'
   developerEmail = 'nisrulz@gmail.com'
 
   licenseName = 'The Apache Software License, Version 2.0'
   licenseUrl = 'http://www.apache.org/licenses/LICENSE-2.0.txt'
   allLicenses = ["Apache-2.0"]
 }
 
 ..
 ..
 
 // Place it at the end of the file
 apply from: 'https://raw.githubusercontent.com/nisrulz/JCenter/master/installv1.gradle'
 apply from: 'https://raw.githubusercontent.com/nisrulz/JCenter/master/bintrayv1.gradle'
 
```  

+ Edit your `local.properties`

```
bintray.user=<your_bintray_username>
bintray.apikey=<your_bintray_apikey>
```
  
+ Now lets setup Bintray before we can push our artifact to it.
  + Register for an account on [bintray.com](https://bintray.com/) and click the activation email they send you.
  + Add a new Maven repository and click **Create New Package**
  + You should now have a maven repository. For instance:
    `https://bintray.com/nisrulz/maven`
  + Now once you have your maven repo setup , click on **Edit**
  
    <amp-img width="400" height="350" layout="responsive" src="/assets/images/posts/uploadtojcenter/edit.jpeg"></amp-img>
    
    and see that you have selected the option `GPG sign uploaded files using Bintray's public/private key pair.` and then click **Update**.
    
    <amp-img width="400" height="100" layout="responsive" src="/assets/images/posts/uploadtojcenter/gpg.jpeg"></amp-img>
    
  
+ Once everything is configured, run the below in your terminal in your root of the project

```gradle
./gradlew install bintrayUpload
```

+ Now once your project is up on bintray, simply hit **Add to Jcenter** button to sync with JCenter.

  <amp-img width="400" height="100" layout="responsive" src="/assets/images/posts/uploadtojcenter/addtojcenter.jpeg"></amp-img>

##### Using your Android "Awesome" Library in other projects
+ Your code is available through the private repo at bintray

```gradle
repositories { 
   jcenter()
   maven { url 'https://dl.bintray.com/<bintray_username>/maven' }
}
dependencies {
  compile 'com.github.<bintray_username>:<library_module>:1.0'
}
```
    
i.e for the sample lib in this repo , `awesomelib`

```gradle
repositories { 
   jcenter()
   maven { url 'https://dl.bintray.com/nisrulz/maven' }
}
dependencies {
  compile 'com.github.nisrulz:awesomelib:1.0'
}
```
  
+ Your code is available through JCenter if you have received the mail with confirmation

    <amp-img width="400" height="20" layout="responsive" src="/assets/images/posts/uploadtojcenter/finalmail.jpeg"></amp-img>

Few things to note when you received the final email.
	+ Goto your maven repo at bintray and verify that you have Jcenter under the **Linked to** section

    <amp-img width="400" height="160" layout="responsive" src="/assets/images/posts/uploadtojcenter/linked.jpeg"></amp-img>

  + Now you would also want to sync the artifact to [MavenCentral](https://search.maven.org/), for that you need to hit the **Maven Central** tab and sync

    <amp-img width="400" height="160" layout="responsive" src="/assets/images/posts/uploadtojcenter/synctomaven.jpeg"></amp-img>

  + Once you hit sync you would see as below. Wait for few hours for the sync to occur.

    <amp-img width="400" height="150" layout="responsive" src="/assets/images/posts/uploadtojcenter/syncstatus.jpeg"></amp-img>

You can use the lib now as follows

```gradle
dependencies {
    compile 'com.github.<bintray_username>:<library_module>:1.0'
  }
```

i.e for the sample lib in this repo , `awesomelib`

```gradle
dependencies {
      compile 'com.github.nisrulz:awesomelib:1.0'
  }
```

+ Let the world know of your **AwesomeLib** 

  > + Add a readme that explains how to integrate and use your Awesome library
  > + Add a license block as in this repo
  > + Also include the Bintray badge provided by Bintray in your readme
  >
  >   <amp-img width="400" height="230" layout="responsive" src="/assets/images/posts/uploadtojcenter/badge.jpeg"></amp-img>
  > + Promote your lib on social media so that others can know about it.
  > + Always add a working sample app in your project that demonstrates your library in use.
  > + Add screenshots if possible in your readme.


The code for the AwesomeLibrary and this guide itself is open sourced abd available on [github](https://github.com/nisrulz/UploadToBintray)

The `bintray` and `install` plugins are also available on [github](https://github.com/nisrulz/JCenter). You may fork it and use it in your namespace.

Star it or just fork it to use it.

This post is first in parts of a series

1. [Guide to publishing your Android Library via Jcenter/Bintray](#)
1. Guide to publishing your Android Library via MavenCentral (..todo)
1. Guide to publishing your Android Library via JitPack (..todo)
