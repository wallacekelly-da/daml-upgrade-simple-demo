
DAR_MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
DAR_MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
DAR_SCRIPTS=scripts/.daml/dist/test-scripts-0.0.1.dar
DAR_MODEL_UPGRADE=upgrade-model/.daml/dist/upgrade-project-1.0.0.dar

UPGRADE_PACKAGE_ID=upgrade-model/package_id

DOCKER_CONFIG="--platform=linux/amd64 --rm --network=host -v ./conf:/home/user/conf"
DAML_UPGRADE_IMAGE="digitalasset-docker.jfrog.io/daml-upgrade:2.1.1"

ALICE_JWT_FILE="conf/alice-hub-jwt.json"
UPGRADE_CONF="conf/upgrade.conf"
CLEANUP_CONF="conf/cleanup.conf"

function jwt_decode(){
    jq -R 'split(".") | .[1] | @base64d | fromjson' <<< "$1"
}

function init_ledger_environment() {

    if [ -f ${ALICE_JWT_FILE} ]; then
        LEDGER_ID=$(jwt_decode $(<${ALICE_JWT_FILE}) | jq -r '.ledgerId')

        _info "Connecting to Hub ledger: ${LEDGER_ID}"

        LEDGER_SCRIPT_CONNECTION="--ledger-host ${LEDGER_ID}.daml.app \
                                  --ledger-port 443 \
                                  --application-id damlhub \
                                  --tls \
                                  --access-token-file ${ALICE_JWT_FILE}"
        LEDGER_DOCKER_CONNECTION="${LEDGER_SCRIPT_CONNECTION}"
    else
        LEDGER_SCRIPT_CONNECTION="--ledger-host localhost --ledger-port 6865"
        LEDGER_DOCKER_CONNECTION="--ledger-host host.docker.internal --ledger-port 6865"
    fi
}

# issue a user friendly red error and die
function _error(){
  _error_msg "$@"
  exit $?
}

# Issue a log message
function _log() {
  echo "$@"
}

# issue a user friendly red error
function _error_msg(){
  local RC=$?
  ((RC)) || RC=1
  echo -e "\e[1;31mERROR: $@\e[0m"
  return ${RC}
}

# issue a user friendly green informational message
function _info(){
  local first_line="INFO: "
  while read -r; do
    printf -- "\e[32;1m%s%s\e[0m\n" "${first_line:-      }" "${REPLY}"
    unset first_line
  done < <(echo -e "$@")
}

# issue a user friendly yellow warning
function _warning(){
  local first_line="WARNING: "
  while read -r; do
    printf -- "\e[33;1m%s%s\e[0m\n" "${first_line:-        }" "${REPLY}"
    unset first_line
  done < <(echo -e "$@")
}

# prints a little green check mark before $@
function _ok(){
  echo -e "\e[32;1m✔\e[0m ${@}"
}

# prints a little red x mark before $@ and sets check to 1 if you are using it
function _nope(){
  echo -e "\e[31;1m✘\e[0m ${@}"
}

function _get_alice_party_id(){
    if [ -f target/alice.json ]; then
         party=$(jq -r '.' < target/alice.json)
    else
        party=$(daml ledger list-parties --host localhost --port 6865 --json \
                    | jq -r 'first(.|map(.party)|.[] | select(contains("alice")))')
    fi

    echo "${party}"
}
