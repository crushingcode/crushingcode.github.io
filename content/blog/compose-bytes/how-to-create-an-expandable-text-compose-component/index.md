---
title: "How to create an Expandable Text compose component"
date: 2025-01-05
authors:
  - name: Nishant Srivastava
    link: /about/
tags: ["compose", "android"]
---

![Banner](../header.jpg)

<!--Short abstract goes here-->

One of the requirements for an app I was working on, was to have a text field that can be expanded to show more text. The pattern seemed to be common in other apps too. This post shows how to build one.

<!--more-->

Using a 3rd party library is always an option, but this is simple enough that one can create a custom Compose component. This is also just my take at creating such a compose component.

Let's get to some code now 👨🏻‍💻

### ExpandableText Compose Component

Create a new file `ExpandableText.kt` and add the following code:

```kt {filename="ExpandableText.kt"}
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow

@Composable
fun ExpandableText(
    text: String,
    modifier: Modifier = Modifier,
    showMoreText: String = "Show more...",
    showLessText: String = "Show less.",
    maxLines: Int = 3,
    style: TextStyle = MaterialTheme.typography.bodyMedium,
    contentTextColor: Color = MaterialTheme.colorScheme.onSurface,
    linkTextColor: Color = Color.Blue
) {
    var showMore by rememberSaveable { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            // Animate content as it changes
            .animateContentSize(animationSpec = tween(durationMillis = 150, easing = LinearEasing))
    ) {

        // Content text
        Text(
            text = text,

            // Used to control how much text is shown when collapsed vs expanded
            maxLines = if (showMore) Int.MAX_VALUE else maxLines,

            // Show ellipsis at the end when content text is collapsed
            overflow = if (showMore) TextOverflow.Clip else TextOverflow.Ellipsis,
            style = style,
            color = contentTextColor
        )

        // Show more/Show less text link
        Text(
            modifier = Modifier
                .clickable(
                    onClick = { showMore = !showMore },
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ),
            text = if (showMore) showLessText else showMoreText,
            style = style,
            color = linkTextColor
        )
    }
}
```

**This is how it looks in action:**

<video controls autoplay muted width=640 src="expandable_text_preview.webm"></video>

Few things that standout in the code above:

- The component has configurable properties such as `style`, `linkTextColor` and `contentTextColor` to allow for custommizing how the text looks.

- You use the standard `Text` compose component to display the content text.

- You use a second `Text` component to display "Show more" and "Show less" text. This is marked to be clickable by using `clickable` modifier, but has the **Ripple Effect** disabled.

  {{< callout type="info" >}}
  Read about disabling Ripple Effect in compose components in my other [post](../removing-ripple-effect-from-clickable-components/)
  {{< /callout >}}

  ```kt {hl_lines=[3,4,5,6,7]}
  Text(
      modifier = Modifier
          .clickable(
              onClick = { showMore = !showMore },
              interactionSource = remember { MutableInteractionSource() },
              indication = null
          ),
      text = if (showMore) showLessText else showMoreText,
      style = style,
      color = linkTextColor
  )
  ```

- `animateContentSize()` is used for animating the text expanding when "Show more" is clicked.

  ```kt {hl_lines=[4]}
  Column(
        modifier = modifier
            .fillMaxWidth()
            .animateContentSize(animationSpec = tween(durationMillis = 150, easing = LinearEasing))
  ) {
    ...
  }
  ```

- `maxLines` is used to control how much text is shown when collapsed vs expanded. This is configurable as it can be passed as an argument to the compose component.

  ```kt {hl_lines=[4]}
  // Content text
  Text(
      // ..
      maxLines = if (showMore) Int.MAX_VALUE else maxLines,
      // ..
  )
  ```

- `overflow` is used to show ellipsis at the end when content text is collapsed.

  ```kt {hl_lines=[4]}
  // Content text
  Text(
      // ...
      overflow = if (showMore) TextOverflow.Clip else TextOverflow.Ellipsis,
      // ...
  )

  ```

Rest of the code is quite simple and uses standard Compose practices 😎
