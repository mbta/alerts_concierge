#!/bin/bash
set -e

unset MIX_ARCHIVES
export MIX_HOME=$SEMAPHORE_CACHE_DIR/mix
mkdir -p $MIX_HOME

export YARN_CACHE_FOLDER=$SEMAPHORE_CACHE_DIR/yarn
mkdir -p $YARN_CACHE_FOLDER

export ASDF_DATA_DIR=$SEMAPHORE_CACHE_DIR/asdf

if [[ ! -d $ASDF_DATA_DIR ]]; then
  mkdir -p $ASDF_DATA_DIR
  git clone https://github.com/asdf-vm/asdf.git $ASDF_DATA_DIR --branch v0.8.0
fi

source $ASDF_DATA_DIR/asdf.sh
asdf update

asdf plugin-add erlang || true
asdf plugin-add elixir || true
asdf plugin-add nodejs || true
asdf plugin-update --all
$ASDF_DATA_DIR/plugins/nodejs/bin/import-release-team-keyring
$ASDF_DATA_DIR/plugins/nodejs/bin/import-previous-release-team-keyring
asdf install

mix local.hex --force
mix local.rebar --force
mix deps.get

npm install -g yarn
yarn install --cwd apps/concierge_site/assets
