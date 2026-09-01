#!/bin/sh
# Run once per clone: makes the security brief run before every commit.
git config core.hooksPath .githooks && echo "Memorio security hooks installed (core.hooksPath=.githooks)"
