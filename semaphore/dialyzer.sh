#!/bin/bash
set -e

mix compile

find $SEMAPHORE_CACHE_DIR -name "dialyxir_*_deps-dev.plt*" -print0 \
  | xargs -0 -I{} cp '{}' _build/dev
mix dialyzer --plt
cp _build/dev/*_deps-dev.plt* $SEMAPHORE_CACHE_DIR

mix dialyzer --halt-exit-status
