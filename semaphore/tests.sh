#!/bin/bash
set -e

MIX_ENV=test mix coveralls.json
bash <(curl -s https://codecov.io/bash)
