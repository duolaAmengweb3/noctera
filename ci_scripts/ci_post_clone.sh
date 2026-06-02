#!/bin/sh
set -e
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null 2>&1; then brew install xcodegen; fi
xcodegen generate
