#!/usr/bin/env bash

# Install Hugo if missing
command -v hugo >/dev/null || brew install hugo

# Serve locally while watching for file changes
hugo mod tidy
hugo server --logLevel warn --disableFastRender -p 1313