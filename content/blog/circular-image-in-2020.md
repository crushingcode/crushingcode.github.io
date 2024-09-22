---
title: "Circular images in 2020"
date: 2020-01-22
authors:
  - name: Nishant Srivastava
    link: /about/
type: blog
draft: true
---

You would have thought that the problem for creating a simple circular image such as the one for an avatar, would have been solved by now. I mea, this is 2020 already! We are gearing up to go to Mars, who cares about this ..pffff!

Well turns out the designers sure do care about it and they get pretty aggressive if you try to tell them anything else. So I was asked to implement simple Avatar View (I really like calling it that :P ). I am no genius and haven't done this for sometime. The very first thing that came to my mind was to do a custom implementation where I extend from ImageView and modify the view before it gets drawn on the screen i.e inside the `onDraw()` call.

However, that seemed far fetched and I was sure I wouldn't need to do this now. After all this is in 2020 we are talking about this.

So I did a quick google search, almost the first page was filled with results that were ranging from custom implementation to various possible hacks to achieve the result.

I didn't give up and jumped into the official Android documentation, searching with keywords such as "Circle" and "Round". This is when something caught my eye, a class I really hadn't heard about. This was part of AndroidX libraries so possibly with all backport possibilities too.

```kotlin
// DrawableExt.kt

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.core.graphics.drawable.RoundedBitmapDrawableFactory


fun Drawable?.makeCircular(context: Context): Drawable? {
    val bmp = this?.convertDrawableToBitmap()
    bmp?.let {
        val drawable = RoundedBitmapDrawableFactory.create(context.resources, it)
        drawable.setAntiAlias(true)
        drawable.isCircular = true
        return drawable
    }
    return null
}

fun Drawable.convertDrawableToBitmap(): Bitmap {
    if (this is BitmapDrawable)
        return this.bitmap
    val bounds = this.bounds
    val width = if (!bounds.isEmpty) bounds.width() else this.intrinsicWidth
    val height = if (!bounds.isEmpty) bounds.height() else this.intrinsicHeight
    val bitmap = Bitmap.createBitmap(
        if (width <= 0) 1 else width, if (height <= 0) 1 else height,
        Bitmap.Config.ARGB_8888
    )
    val canvas = Canvas(bitmap)
    this.setBounds(0, 0, canvas.width, canvas.height)
    this.draw(canvas)
    return bitmap
}
```

Above api 21 and imageview clipping

```kotlin
import android.os.Build
import android.view.View
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
fun View?.clipToCircle() {
    this?.apply {
        clipToOutline = true
        // Set to null to disable shadows
        outlineProvider = CircularOutlineProvider
    }
}
```

```kotlin
import android.graphics.Outline
import android.os.Build
import android.view.View
import android.view.ViewOutlineProvider
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
object CircularOutlineProvider : ViewOutlineProvider() {
    override fun getOutline(view: View, outline: Outline) {
        outline.setOval(
            view.paddingLeft,
            view.paddingTop,
            view.width - view.paddingRight,
            view.height - view.paddingBottom
        )
    }
}

```

```kotlin
val imageDrawable = ContextCompat.getDrawable(this, R.drawable.puppy)

if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    imageView.setImageDrawable(imageDrawable)
    imageView.clipToCircle()
} else {
    imageView.setImageDrawable(imageDrawable.circular(this))
}
```

Using Picasso Circle Transform
Using Glide Circle Transform
Using Clipping
Using RoundedDrawable
Using CustomView: CircleImageView
