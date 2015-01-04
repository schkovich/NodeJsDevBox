#!/bin/bash
set -uex

export PUPPET_ENV=development
export PUPPET_HOST=local
export PUPPET_DOMAIN=wordpress.dev
export VAGRANT_LOG=debug
export PUPPET_WDIR=/home/vagrant/opt/puppet
vagrant provision --provision-with puppet
