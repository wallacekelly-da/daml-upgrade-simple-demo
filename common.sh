
MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
MODEL_UPGRADE=upgrade-model/.daml/dist/upgrade-project-1.0.0.dar

UPGRADE_PACKAGE_ID=upgrade-model/package_id
ALICE_PARTY_ID=alice_party_id

DAML_UPGRADE_IMAGE=digitalasset-docker.jfrog.io/daml-upgrade:2.1.0

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
  echo -e "\e[1;31mERROR: $@\e[0m" >&2
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
