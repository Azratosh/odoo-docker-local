#!/usr/bin/env bash

# Exit immediately if any error occurs
set -o errexit

readonly REQUIRED_ENV_VARS=(
  "ODOO_PASSWORD"
)


check_env_vars() {
  for REQ_ENV_VAR in "${REQUIRED_ENV_VARS[@]}"; do
    if [[ -z "${!REQ_ENV_VAR}" ]]; then
      echo -e "ERROR: \
      \nEnvironment variable \"$REQ_ENV_VAR\" not set. \
      \nMake sure you have the following environment variables set:\n"

      echo "${REQUIRED_ENV_VARS[@]}"

      echo -e "\nAborting."
      exit 1
    fi
  done
}

init() {
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE odoo LOGIN PASSWORD '${ODOO_PASSWORD}';
  ALTER ROLE odoo WITH CREATEDB;
EOSQL
}

main() {
  check_env_vars
  init
}

main "$@"
