#!/usr/bin/env bash


# Check if Hugo is installed
hugo version
if [ $? -eq 0 ]; then
    echo OK
else
    echo "Hugo is not installed/configured"
    # Install Hugo
    brew install hugo
fi

# Serve locally while watching for file changes
hugo mod tidy
hugo server --logLevel debug --disableFastRender -p 1313