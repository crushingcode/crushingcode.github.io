---
title: "Hunting Kotlin Synthetics For Views"
date: 2022-03-02
authors:
  - name: Nishant Srivastava
    link: /about/
cascade:
  type: docs
---

![Banner](img/hunting-kotlin-synthetics-for-views/banner.png)

<!--more-->

Kotlin Synthetics for Views is deprecated! You can read about it [here](https://android-developers.googleblog.com/2022/02/discontinuing-kotlin-synthetics-for-views.html).

That means if you have been using them in your project then you need to replace them with a more recommended approach i.e [ViewBindings](https://developer.android.com/topic/libraries/view-binding). There is a [migration guide](https://developer.android.com/topic/libraries/view-binding/migration) too.

But before you can start the migration you need to track down the files where Kotlin Synthetics are being used. Lets find out.

Run the below command at the root of your project in a terminal window:

```sh
grep -rwl . -e 'kotlinx.android.synthetic'
```

here

- `-r` = Recursive
- `-w` = Match the whole word
- `-l` = Output the file name of matching files
- `-e` = Match pattern used during the search

On executing the above command, the output is like below:

```sh
❯ grep -rwl . -e 'kotlinx.android.synthetic'
./UsingKotlin/app/src/main/java/nisrulz/github/sample/usingkotlin/MainActivity.
```

Incase you are only interested in finding out the number of files where Kotlin Synthetics are being used, run the below command:

```sh
grep -rwl . -e 'kotlinx.android.synthetic' | wc -l
```

On executing the above command, the output is like below:

```sh
❯ grep -rwl . -e 'kotlinx.android.synthetic' | wc -l
       1
```

That is all! Once you have found the places in your codebase where Kotlin Synthetics have been used, simply replace them with ViewBinding one by one. You could also completely switch to [Jetpack Compose](https://developer.android.com/jetpack/compose), if you want to switch to the next generation of UI development framework on Android.
