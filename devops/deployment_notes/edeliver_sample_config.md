# May not be worth having 2 environments till we move out of alpha/beta

STAG_1="xx.xx.xxx.xx"
STAG_2="xx.xx.xxx.xx"
PROD_1="xx.xx.xxx.xx"
PROD_2="xx.xx.xxx.xx"

BUILD_HOST="xx.xx.xxx.xx"
BUILD_USER="ubuntu"
BUILD_AT="/home/ubuntu/builds"

STAGING_HOSTS="$STAG_1 $STAG_2"
STAGING_USER="ubuntu"
TEST_AT="/home/ubuntu/web"

PRODUCTION_HOSTS="$PROD_1 $PROD_2"
PRODUCTION_USER="ubuntu"
DELIVER_TO="/home/ubuntu/web"

LINK_VM_ARGS="/home/ubuntu/vm.args"
APP="concierge_site" # or "alert_processor"

# TODO: Handling of ENV Vars?

# For *Phoenix* projects, symlink prod.secret.exs to our tmp source
# Since both staging and production are build with a MIX_ENV of :prod, for staging
# We just symlink a different secret file
pre_erlang_get_and_update_deps() {
  if [ "$DEPLOY_ENVIRONMENT" = "staging" ]; then
    local _prod_secret_path="/home/ubuntu/secrets/stag.secret.exs"
    if [ "$TARGET_MIX_ENV" = "prod" ]; then
      __sync_remote "
        ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
      "
    fi
  fi

  if [ "$DEPLOY_ENVIRONMENT" = "production" ]; then
    local _prod_secret_path="/home/ubuntu/secrets/prod.secret.exs"
    if [ "$TARGET_MIX_ENV" = "prod" ]; then
      __sync_remote "
        ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
      "
    fi
  fi
}
