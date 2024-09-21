#!/usr/bin/env bash

read -p "  ❓  Title of your new post?   : " TITLE

# Convert to small case
SMALL_CASE_TITLE="$(tr [A-Z] [a-z] <<< "$TITLE")"

# Replace whitespace with hyphen
SMALL_CASE_TITLE_WITH_HYPHEN="${SMALL_CASE_TITLE// /-}"

# Create Git branch
git checkout -b post/$SMALL_CASE_TITLE_WITH_HYPHEN

# Create the markdown file
POST_FILE="content/posts/$SMALL_CASE_TITLE_WITH_HYPHEN.md"
touch $POST_FILE
CURRENT_DATE=$(date +%F)
echo """---
title: \"$TITLE\"
date: \"$CURRENT_DATE\"
authors:
  - name: Nishant Srivastava
    link: /about/
type: blog
---

<!--Short bbstract goes here-->

<!--more-->
""" >> $POST_FILE

# Create the images directory
mkdir static/images/posts/$SMALL_CASE_TITLE_WITH_HYPHEN

# Add to Git
git add .
git commit -m "added new post $SMALL_CASE_TITLE_WITH_HYPHEN"
