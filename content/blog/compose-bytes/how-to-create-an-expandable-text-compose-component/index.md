---
title: "How to create an Expandable Text compose component"
date: "2025-01-04"
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](../header.jpg)

<!--Short abstract goes here-->

<!--more-->

```kt
@Composable
fun ExpandableText(
    text: String,
    showMoreText: String = "Show more...",
    showLessText: String = "Show less.",
    maxLines: Int = 3,
    style: TextStyle = MaterialTheme.typography.bodySmall,
    contentTextColor: Color = MaterialTheme.colorScheme.onSurface,
    linkTextColor: Color = MaterialTheme.colorScheme.inversePrimary,
    modifier: Modifier = Modifier
) {
    var showMore by rememberSaveable { mutableStateOf(false) }

    Column(
        modifier = modifier
            .animateContentSize(animationSpec = tween(durationMillis = 100, easing = LinearEasing))
    ) {
        if (showMore) {
            Text(text = text, style = style, color = contentTextColor)
        } else {
            Text(
                text = text,
                maxLines = maxLines,
                overflow = TextOverflow.Ellipsis,
                style = style,
                color = contentTextColor
            )
        }

        Text(
            modifier = Modifier
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) { showMore = !showMore },
            text = if (showMore) showLessText else showMoreText,
            style = style,
            color = linkTextColor
        )
    }
}

@PreviewLightDark
@Composable
private fun Preview() {
    ComposeBytesPlaygroundPreviewTheme {
        ExpandableText(
            text = prepareLongText()
        )
    }

}
```