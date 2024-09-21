---
title: "Signing Android Apps"
date: 2022-03-03
authors:
  - name: Nishant Srivastava
    link: /about/
cascade:
  type: docs
---

![Banner](img/signing-android-apps/banner.png)

<!--more-->

As an Android Engineer, I have to sign Android apps whenever making a public release. The steps are quite simple and well [documented on the official website](https://developer.android.com/studio/publish/app-signing). However the one thing that always comes up how do you provide your signing credentials and keystore file. Lets find out!

There 2 common ways this can be done:

## Using ENV vars (Recommended)

Inside your `~/.zshrc` or `~/.bashrc` file, declare the key value pairs as shown below:

> Note: For CI, declare key-value pair under secrets section

```sh
export KEYSTORE_FILE_PATH = "/Users/your_user/App_Directory/keystore_file.keystore"
export KEYSTORE_PASSWORD = "********"
export KEY_ALIAS = "key_alias"
export KEY_PASSWORD = "************"
```

Then inside your app module's build.gradle file, you can reference it as shown below:

```groovy
signingConfigs {
    release {
        storeFile file(String.valueOf(System.getenv("KEYSTORE_FILE_PATH")))
        storePassword System.getenv("KEYSTORE_PASSWORD")
        keyAlias System.getenv("KEY_ALIAS")
        keyPassword System.getenv("KEY_PASSWORD")
    }
}
```

## Using local.properties file

Inside your `local.properties` file, declare the key value pairs as shown below:

```sh
storeFile=../keystore.jks
storePassword=example
keyAlias=example
keyPassword=example
```

> Note: `keystore.jks` file is the Keystore file that is expected to be placed inside the root directory of your project.

Next create a `signing.gradle` file at the root of your project and add the below code in it:

```groovy
def keystorePropertiesFile = rootProject.file("local.properties")

if (keystorePropertiesFile.exists()) {
	// Load the properties
	def keystoreProperties = new Properties()
	keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
	android {
		signingConfigs {
			if (keystorePropertiesFile.exists()) {
				release {
					keyAlias keystoreProperties['keyAlias']
					keyPassword keystoreProperties['keyPassword']
					storeFile file(keystoreProperties['storeFile'])
					storePassword keystoreProperties['storePassword']
				}
			}
		}

		buildTypes {
			release {
				if (keystorePropertiesFile.exists()) {
					signingConfig signingConfigs.release
				}
			}
		}
	}
} else {
	println("Filename: keystore.properties")
	println("Error: File does not exists")
	println("Solution: Create a keystore.properties file with valid details under keystore directory at the root of your project")
}
```

Now in order to use this `signing.gradle` config in your app, open the `build.gradle` file for app module and add the the below line of code just above the `android {}` block:

```groovy

apply from: "$rootProject.projectDir/signing.gradle"

// android { ... }
```

Thats all!

In both cases, simply sync your project and you should be able to sign your APK file by executing `./gradlew assembleRelease` 🎉
