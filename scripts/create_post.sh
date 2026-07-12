#!/usr/bin/env bash

read -p "  ❓  Title of your new post?   : " TITLE

# Convert to small case
SMALL_CASE_TITLE="$(tr [A-Z] [a-z] <<< "$TITLE")"

# Replace whitespace with hyphen
SMALL_CASE_TITLE_WITH_HYPHEN="${SMALL_CASE_TITLE// /-}"

# Create Git branch
git checkout -b blog/post/$SMALL_CASE_TITLE_WITH_HYPHEN

# Create the markdown file
mkdir -p "content/blog/$SMALL_CASE_TITLE_WITH_HYPHEN"
POST_FILE="content/blog/$SMALL_CASE_TITLE_WITH_HYPHEN/index.md"
touch $POST_FILE
CURRENT_DATE=$(date +%F)

echo """---
title: \"$TITLE\"
date: \"$CURRENT_DATE\"
authors:
  - name: Nishant Srivastava
    link: /about/
---

![Banner](header.jpg)

<!--Short abstract goes here-->

<!--more-->
""" >> $POST_FILE

# Add to Git
git add .
git commit -m "added new blog post $SMALL_CASE_TITLE_WITH_HYPHEN"
