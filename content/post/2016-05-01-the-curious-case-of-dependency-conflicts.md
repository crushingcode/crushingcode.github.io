+++
author = "Nishant"
date = "2016-05-02T10:54:24+02:00"
draft = false
title = "The curious case of dependency conflicts"
slug = "the-curious-case-of-dependency-conflicts"
tags = ["gradle","conflict","issue","solution"]
comments = true     # set false to hide Disqus comments
share = true        # set false to share buttons
+++

If I were to ask a question to a room filled with android developers

>**"How many of you have been in that place of sheer helplessness and panic when your gradle build fails because of a version conflict in dependencies?"**

..I am pretty sure a lot of them would raise their hand or agree to being in that state and the very first action would be to hop onto stackoverflow and search for possible solutions in this type of a situation.

![depconflicts](/images/posts/depconflicts.jpg)
<!-- Image taken from freepik.com and all credit goes to the creator of it -->

We all have been there and we all have experienced it. The problem is a result of each library following a completely different development lifecycle and using a different version of a public api, which by far all means is not the problem which needs to be rectified.
You can't just ask all android library developers/team maintaining it to update the library to use either the lastest or some specific version of a dependency just because it works with another library and/or is causing a conflict when you have both of them in your project.

So what exactly are the options available to us..

I stumbled upon such a situation sometime back in the last month or so and as the whole journey to fix this type of conflict was suprisingly less documented on the web , here is my record of how I solved it.

Now the process I followed may not be the best one out there but it sure did led me to hunt down the solution along with digging out some pretty neat tricks possible using ***Gradle Build System***.

Before we begin lets get acquinted with some terms we would be using a lot in this whole writeup.

+ **gradle** - Build system for android
+ **dependency** - Libraries such as support libraries in your build.gradle
+ **transitive dependency** - Libraries on which dependencies defined in your project depend on
+ **conflict** - incompatible or at variance/clash
+ **gradlew** - gradle wrapper

The important term here for us (in regards to our problem of conflicting dependencies) is ***transitive dependency***.

You see when you have multiple dependencies defined in your build.gradle, you can never be sure of what do those dependencies further depend on.

Lets take a simple example

Say you have 3 android libraries defined under your build.gradle for the app , namely **libA**, **libB** and **libC**.

```gradle

dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
    compile 'com.company1.sdk:libA:1.0.2'
    compile 'com.company2.sdk:libB:2.0.3'
    compile 'com.company3.sdk:libC:3.0.4'
}

```

Now for you as an android dev the only dependencies in view are **libA**, **libB** and **libC**. You have no idea what these android libraries furthur depend upon.

The situation which might cause a conflict would be if **libA** depends on say **libD** (version 4.0.4) and **libC** depends on say **libD** (version 4.0.2).

Now by default *Gradle* would resolve to the latest version of **libD**. But this is where the problem actually lies.

You see when you build your code it only says there is conflict in the **libD** dependency. Thats all.

So how do you hunt it down.

well there are a few ways you can do that, the easiest one uses the `gradle wrapper`.

### **STEP 1**
Look for all android dependencies being downloaded as part of the build process.

```bash
./gradlew androidDependencies
```

..you should get a graph like this

```bash
...
release
+--- com.company1.sdk:libA:1.0.2
|    +--- com.company4.sdk:libD:4.0.4
+--- com.company2.sdk:libB:2.0.3
|
+--- com.company3.sdk:libA:3.0.4
     +--- com.company4.sdk:libD:4.0.2
```
..hmm..its becoming a bit more clear now. We can see which version of transitive dependencies are being pulled by which dependency.


So what exactly happened here?  

The declared dependencies inside your build.gradle file actually download some more libraries on their own since its integral to their functioning. Transitive dependency defined for a declared library could conflict with another transitive dependeny defined for another declared library in version.

Whats wrong here, you ask  ?  When a library was written to work with older version of the ***transitive  dependency*** then it will basically break if provided with a higher version of the same, probably because the API changed or some classes were removed/renamed (between version updates)from what it was coded to reference and work with.

Well if you are able to find your problem then you can jump to the solution directly, but if you are still looking for answers then read on.

Looks like you are still in trouble!

Considering that you still cannot find the conflicting dependencies and their versions and assuming that its not conflicting from a dependency declared in the build.gradle file but (..probably) introduced by some gradle-plugin defined, we will do a more verbose checkup which is what STEP 2 is about

### **STEP 2**
Check the complete stacktrace of the build process using `--info` and `--stacktrace` flags passed as arguments

```bash
./gradlew build --info --stacktrace
```
This should give you a complete log of everything and where exactly the build failed.You can find out the version conflicts and a lot more details in this step.

In my case this was the very case where I was having a conflict on annotations library introduced by the findbugs gradle plugin.


Well, ok so this is a problem we have got. Whats the solution ? how do you go against the default behaviour of gradle and resolve to a lower version when a conflict occurs ?

### **SOLUTION**

Well this is where the flexibility of Gradle comes into view. This is not commonly known but is a very useful functionality tucked away into the [api docs](https://docs.gradle.org/current/dsl/org.gradle.api.artifacts.ResolutionStrategy.html#org.gradle.api.artifacts.ResolutionStrategy:failOnVersionConflict()) for gradle.

The very first thing that you should do is, enable `failOnVersionConflict` flag in gradle on version conflicts.

```gradle

configurations.all {
  resolutionStrategy.failOnVersionConflict()
}

```
This should give you more idea about where in your code are version conflicts occuring which were getting implicitly resolved by gradle.

Secondly, you can force gradle to resolve to the lower version

```gradle
configurations.all {
  resolutionStrategy.force 'com.company4.sdk:libD:4.0.2'
}

```

This changes the default behaviour of gradle.

But wait! Resoltion strategy is still causing parts of the same dependency to conflict. HELP!

Well only in that condition you should try and completely replace the whole module.

Ho do you do it ? by including the below into your `build.gradle` file.

```gradle
// add dependency substitution rules
configurations.all {
  resolutionStrategy.dependencySubstitution {
    // Substitute one module dependency for another
    substitute module('com.company4.sdk:libD:4.0.4') with module('com.company4.sdk:libD:4.0.2')
  }
}
```

> NOTE : dependencySubstitution is an incubating functionality and may change in a future version of Gradle
> As of writting this post the latest Gradle Version is 2.13 in which this is available.

Thats pretty neat , isn't it.

I am pretty sure this would enable you to find the conflicts and solve it too.

This also goes with the disclaimer that trying to resolve dependency conflicts this way is not the preferred way. You should always try to be using the latest version of the dependencies as well as maintain your library to use the same. This post basically defines the process to enable you to try and figure out why your build is failing and how to bypass it for the time being.

Thats all for today folks.
Keep crushing code until next post :)

Reference : [Gradle Docs](https://docs.gradle.org/current/dsl/org.gradle.api.artifacts.ResolutionStrategy.html#org.gradle.api.artifacts.ResolutionStrategy:failOnVersionConflict())
