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
  modifier: Modifier = Modifier,
  minimizedMaxLines: Int = 3,
  style: TextStyle = MaterialTheme.typography.bodySmall,
  color: Color = MaterialTheme.colorScheme.onSurface,
  showMoreText: String = stringResource(R.string.cosma_show_more),
  showLessText: String = stringResource(R.string.cosma_show_less)
) {
  var showMore by rememberSaveable { mutableStateOf(false) }

  Column(
    modifier = modifier
      .animateContentSize(animationSpec = tween(100))
  ) {
    if (showMore) {
      Text(text = text, style = style, color = color)
    } else {
      Text(
        text = text,
        maxLines = minimizedMaxLines,
        overflow = TextOverflow.Ellipsis,
        style = style,
        color = color
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
      color = MaterialTheme.colorScheme.link
    )
  }
}

@PreviewUiThemes
@Composable
private fun Preview() {
  val loremIpsumText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nec odio"
  val longText = StringBuilder().apply {
    repeat(10) {
      append(loremIpsumText)
      append(". ")
    }
  }.toString()


    ExpandableText(
      text = longText,
      minimizedMaxLines = 4
    )
  
}
```