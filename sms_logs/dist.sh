#!/bin/sh

set -euo pipefail

npm run check
npm run build

rm dist/bundle.zip || true
zip dist/bundle.zip dist/main.cjs

echo "Bundle built in dist/bundle.zip"
