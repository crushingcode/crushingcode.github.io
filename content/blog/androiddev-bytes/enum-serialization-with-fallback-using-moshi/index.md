---
title: "Enum serialization with fallback using Moshi"
date: "2025-01-04"
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](../header.jpg)

<!--Short abstract goes here-->

When working with Enum serialization using Moshi, it is important to have fallbacks in case the enum value returned in response is not present in the predefined list of enum values. In this post, you will see how to achieve this.

<!--more-->

Suppose you have an Enum class defined as:

```kt
enum class Status {
  ACTIVE,
  INACTIVE
}
```

and the domain model class (with Moshi wired in) is defined as:

```kt
@JsonClass(generateAdapter = true)
data class InfoData(
    val id: Long,
    val status: Status,
)
```

which corresponds to returned response JSON:

```json
{
  "id": 123,
  "status": "ACTIVE" // or INACTIVE
}
```

{{< callout type="info" >}}
In this blog post you will be using Retrofit + Moshi (codegen) to make requests and receive responses.
{{< /callout >}}

To allow for serialization via Moshi, you would have the setup like below (all other code is ommited to keep the example simple):

```kt
// ...Code for setting up OkHttp Client, BASE_URL, HttpLoggingInterceptor, etc

// Setup Moshi
private val moshi = Moshi.Builder()
                        .build()

// Setup Retrofit
private var retrofit: Retrofit = Retrofit.Builder()
    .baseUrl(BASE_URL)
    .client(client)
    .addConverterFactory(MoshiConverterFactory.create(moshi))
    .build()

// Setup API Service
val infoApiService = retrofit.create(InfoApi::class.java)
```

If you make a request using the `infoApiService`:

```kt
viewModelScope.launch {
  val response = infoService.getInfoData()
}
```

Your `InfoApi` will be called and the response will be returned. This can be checked from the logs:

{{< callout type="info" >}}
I have created and used a Mocked API. You can create it easily and quickly using [Mocky](https://designer.mocky.io/).
The URL might now work in future, but you can use your own new URL created by setting up response json in the `Mocky` dashboard.
{{< /callout >}}

```txt
--> GET https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b
--> END GET
tagSocket(97) with statsTag=0xffffffff, statsUid=-1
<-- 200 OK https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b (450ms)
Content-Type: application/json; charset=UTF-8
Date: Sat, 04 Jan 2025 09:06:57 GMT
Content-Length: 38
Sozu-Id: 01JGR92KR0GMJSN8GRZZKZ6FR9
{
  "id": 123,
  "status": "ACTIVE"

}
<-- END HTTP (38-byte body)
InfoData(id=123, status=ACTIVE)
```

{{< callout type="info" >}}
Note the returned response is succesfully serialized to `InfoData(id=123, status=ACTIVE)` object.
{{< /callout >}}

All of this is as expected and quite straightforward.

### Handling unknown returned value

**_But what happens when the returned response contains anything other than the list of entries in the `Status` enum class? What happens on serialization of the response?_**

You can give it a try by modfiying the mocked response that returns status as `NO_NETWORK` when you make the same request.

```json
{
  "id": 123,
  "status": "NO_NETWORK"
}
```

Make the request. Check the logs:

```txt
--> GET https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b
--> END GET
tagSocket(99) with statsTag=0xffffffff, statsUid=-1
<-- 200 OK https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b (175ms)
Content-Type: application/json; charset=UTF-8
Date: Sat, 04 Jan 2025 09:07:19 GMT
Content-Length: 42
Sozu-Id: 01JGR939WXHZ276NA51HH7M13D
{
  "id": 123,
  "status": "NO_NETWORK"

}
<-- END HTTP (42-byte body)

FATAL EXCEPTION: main
Process: com.example.composebytesplayground, PID: 10796
  com.squareup.moshi.JsonDataException: Expected one of [ACTIVE, INACTIVE] but was NO_NETWORK at path $.status
    at com.squareup.moshi.StandardJsonAdapters$EnumJsonAdapter.fromJson(StandardJsonAdapters.java:296)
    at com.squareup.moshi.StandardJsonAdapters$EnumJsonAdapter.fromJson(StandardJsonAdapters.java:264)
    at com.squareup.moshi.internal.NullSafeJsonAdapter.fromJson(NullSafeJsonAdapter.java:41)
    at com.example.composebytesplayground.network.InfoDataJsonAdapter.fromJson(InfoDataJsonAdapter.kt:41)
    at com.example.composebytesplayground.network.InfoDataJsonAdapter.fromJson(InfoDataJsonAdapter.kt:21)
    at com.squareup.moshi.internal.NullSafeJsonAdapter.fromJson(NullSafeJsonAdapter.java:41)
    at retrofit2.converter.moshi.MoshiResponseBodyConverter.convert(MoshiResponseBodyConverter.java:46)
    at retrofit2.converter.moshi.MoshiResponseBodyConverter.convert(MoshiResponseBodyConverter.java:27)
    at retrofit2.OkHttpCall.parseResponse(OkHttpCall.java:246)
    ...
```

{{< callout type="warning" >}}
A fatal crash because of:

`JsonDataException: Expected one of [ACTIVE, INACTIVE] but was NO_NETWORK at path $.status`
{{< /callout >}}

Now that is an issue 🤔

### Why is this happening?

Usually this happens when Backend decides to change the response values without informing the frontend. In this case, the backend is sending a `NO_NETWORK` status, but the frontend is expecting only one of the 2 values: `ACTIVE` and `INACTIVE`. Any new values returned outside the list of those 2 values will cause the crash. This is because an Enum class is a typed class and when Moshi tries to serialize it to this typed class it cannot understand what it needs to serialize it to when the value is outside the defined entries of the Enum class.

### Solution

The ideal solution is to have a way to tell Moshi to ignore unknown values.

For that to work, you first need to modify the `Status` enum class to also accept a new kind of value: `UNKNOWN`.

```kt
enum class Status {
    ACTIVE,
    INACTIVE,
    UNKNOWN
}
```

Next, you need to tell Moshi to use this `UNKNOWN` value as fallback when it encounters unknown values when serializing to the `Status` enum class.

To do this, Moshi comes with an adapter called [EnumJsonAdapter](https://square.github.io/moshi/1.x/moshi-adapters/adapters/com.squareup.moshi.adapters/-enum-json-adapter/index.html). For this to work, you need to add the dependecy to your `build.gradle.kts` file first and sync:

```kt {filename=build.gradle.kts}
dependencies {
    // Other dependencies
    implementation("com.squareup.moshi:moshi-adapters:1.15.2") // or the latest version
}

```

The usage looks like this:

```kt
EnumJsonAdapter
  .create(EnumClass::class.java)
  .withUnknownFallback(EnumClass.UNKNOWN) // EnumClass.UNKNOWN is an entry defined inside EnumClass.
  .nullSafe()
```

To use this you need to modify your `Moshi` instance to add the `EnumJsonAdapter` to the list of adapters, which handles the `Status` enum class by providing a fallback value:

```kt {hl_lines=[2,3,4,5,6]}
private val moshi = Moshi.Builder()
        .add(Status::class.java,
              EnumJsonAdapter.create(Status::class.java)
               .withUnknownFallback(Status.UNKNOWN)
               .nullSafe()
            )
        .build()

// ... rest of the code remains the same
```

Make the request. Check the logs:

```txt
--> GET https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b
--> END GET
tagSocket(97) with statsTag=0xffffffff, statsUid=-1
<-- 200 OK https://run.mocky.io/v3/b3089b64-3a4a-4b16-87b9-a7d19055e37b (343ms)
Content-Type: application/json; charset=UTF-8
Date: Sat, 04 Jan 2025 09:10:41 GMT
Content-Length: 42
Sozu-Id: 01JGRBPBN44F7HNENVCEAR12A2
{
  "id": 123,
  "status": "NO_NETWORK"

}
<-- END HTTP (42-byte body)
InfoData(id=123, status=UNKNOWN)
```

{{< callout type="info" >}}
No crash, phew 😅

Note the returned response is succesfully serialized to `InfoData(id=123, status=UNKNOWN)`, where `status` has the correct fallback value set to `UNKNOWN` 🎉
{{< /callout >}}

### Improvement

Although the actual problem is solved with solution demonstrated above, but you can go a step further and prepare a reusable and shorter way of defining this fallback value for enum in your Moshi instance by abstracting away the logic into an extension function.

You can create a new file named `MoshiExt.kt` in your project and add the following code:

````kt {filename="MoshiExt.kt"}
import com.squareup.moshi.JsonAdapter
import com.squareup.moshi.Moshi
import com.squareup.moshi.adapters.EnumJsonAdapter

/**
 * A Moshi adapter for handling unknown enum values.
 *
 * This adapter will use a specified fallback value for any unknown enum values encountered during deserialization.
 *
 * @param enumType The class of the enum.
 * @param unknownValue The fallback value to use for unknown enum values.
 * @return A JsonAdapter for the specified enum type.
 *
 * Usage example:
 * ```
 * enum class Status {
 *     ACTIVE,
 *     INACTIVE,
 *     UNKNOWN
 * }
 *
 * val moshi = Moshi.Builder()
 *     .add(UnknownEnumMoshiJsonAdapter.create(Status::class.java, Status.UNKNOWN))
 *     .build()
 *
 * val json = "\"NEW\""
 * val adapter = moshi.adapter(Status::class.java)
 * val status = adapter.fromJson(json)
 *
 * println(status) // Output: UNKNOWN
 * ```
 *
 * For more information, see the [EnumJsonAdapter](https://square.github.io/moshi/1.x/moshi-adapters/adapters/com.squareup.moshi.adapters/-enum-json-adapter/index.html) documentation.
 */
object UnknownEnumMoshiJsonAdapter {
    fun <T : Enum<T>> create(enumType: Class<T>, unknownValue: T): JsonAdapter<T> =
        EnumJsonAdapter.create(enumType)
            .withUnknownFallback(unknownValue)
            .nullSafe()
}

/**
 * Extension function for Moshi.Builder to add an EnumJsonAdapter with a fallback for unknown values.
 *
 * This function simplifies the process of adding an EnumJsonAdapter that handles unknown enum values
 * by falling back to a specified default value.
 *
 * @param unknownValue The fallback value to use for unknown enum values.
 * @return The Moshi.Builder instance with the added adapter.
 *
 * Usage example:
 * ```
 * enum class Status {
 *     ACTIVE,
 *     INACTIVE,
 *     UNKNOWN
 * }
 *
 * val moshi: Moshi = Moshi.Builder()
 *     .addFallbackEnumJsonAdapter<Status>(Status.UNKNOWN)
 *     .build()
 * ```
 */
inline fun <reified T : Enum<T>> Moshi.Builder.addFallbackEnumJsonAdapter(unknownValue: T): Moshi.Builder =
    this.add(T::class.java, UnknownEnumMoshiJsonAdapter.create(T::class.java, unknownValue))

````

Using the above extension function `addFallbackEnumJsonAdapter` in our Moshi instance is straightforward:

```kt {hl_lines=[2]}
private val moshi = Moshi.Builder()
        .addFallbackEnumJsonAdapter<Status>(Status.UNKNOWN)
        .build()

// ... rest of the code remains the same.
```

Everything should work like before 👨🏻‍💻

### Tests

Let's also write Unit tests to make sure everything is working as expected:

```kt {filename="UnknownEnumMoshiJsonAdapterTest.kt"}
import com.google.common.truth.Truth.assertThat
import com.squareup.moshi.JsonAdapter
import com.squareup.moshi.Moshi
import org.junit.Test

internal class UnknownEnumMoshiJsonAdapterTest {

    private val moshi: Moshi = Moshi.Builder()
        .addFallbackEnumJsonAdapter<Status>(Status.UNKNOWN)
        .build()

    private val adapter: JsonAdapter<Status> = moshi.adapter(Status::class.java)

    @Test
    fun `SHOULD return known value ACTIVE when deserialization is successful`() {
        val json = "\"ACTIVE\""
        val status = adapter.fromJson(json)
        assertThat(status).isEqualTo(Status.ACTIVE)
    }

    @Test
    fun `SHOULD return known value INACTIVE when deserialization is successful`() {
        val json = "\"INACTIVE\""
        val status = adapter.fromJson(json)
        assertThat(status).isEqualTo(Status.INACTIVE)
    }

    @Test
    fun `SHOULD return unknown value when deserialization encounters unknown value`() {
        val json = "\"NEW\""
        val status = adapter.fromJson(json)
        assertThat(status).isEqualTo(Status.UNKNOWN)
    }

    @Test
    fun `SHOULD return null when deserialization encounters null value`() {
        val json = "null"
        val status = adapter.fromJson(json)
        assertThat(status).isNull()
    }

    @Test
    fun `SHOULD serialize known value correctly`() {
        val status = Status.ACTIVE
        val json = adapter.toJson(status)
        assertThat(json).isEqualTo("\"ACTIVE\"")
    }

    @Test
    fun `SHOULD serialize unknown value correctly`() {
        val status = Status.UNKNOWN
        val json = adapter.toJson(status)
        assertThat(json).isEqualTo("\"UNKNOWN\"")
    }

    @Test
    fun `SHOULD serialize null value correctly`() {
        val status: Status? = null
        val json = adapter.toJson(status)
        assertThat(json).isEqualTo("null")
    }

    private companion object {
        enum class Status {
            ACTIVE,
            INACTIVE,
            UNKNOWN
        }
    }
}
```

Done 🚀
