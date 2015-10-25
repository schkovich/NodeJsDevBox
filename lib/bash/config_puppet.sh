#!/bin/bash
set -uex

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

PUPPET_WDIR="${1:-${HOME}/opt/puppet}"
SYNC_DIR="${2:-${HOME}/lib/puppet/tombox}"
HELPERS="${3:-${HOME}/lib/bash/common/helpers.sh}"
EXCLUDE_PATH=$4
PROVIDER_NAME=$5

source "${DIR}/${HELPERS}"

function configure {
  local DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

  createDirectory "${PUPPET_WDIR}"
  cd "${PUPPET_WDIR}"
  rsync  -avh --no-compress --progress --delete --exclude-from="${EXCLUDE_PATH}" "${SYNC_DIR}/" ./
  # librarian looking for the home folder
  # https://github.com/rodjek/librarian-puppet/issues/258
  if [ "${PROVIDER_NAME}" -eq "virtualbox" ]
    then
      export HOME=/home/vagrant
  else
      export HOME=/home/ubuntu
  fi

  if [ ! -d "vendors" ]
    then
    librarian-puppet config path vendors --local
    librarian-puppet config rsync true --local
    librarian-puppet install --clean --verbose
  else
    librarian-puppet update --verbose
  fi;
}

configure
