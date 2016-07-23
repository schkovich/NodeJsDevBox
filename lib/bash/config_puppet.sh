#!/bin/bash
set -uex

PUPPET_WDIR="${1:-/etc/puppetlabs/code/environments/development}"

function configure {

  cd "${PUPPET_WDIR}"
  # wtf?!! librarian looks for things in the home folder
  # https://github.com/rodjek/librarian-puppet/issues/258
  if [ -z ${JUJU_ENV_NAME+x} ]
    then
      export HOME=/home/vagrant
  else
      export HOME=/home/ubuntu
  fi

  if [ ! -d "vendors" ]
    then
    librarian-puppet config path vendors --local
    librarian-puppet config rsync true --local
    librarian-puppet install --verbose
  else
    librarian-puppet update --verbose
  fi;
}

configure
