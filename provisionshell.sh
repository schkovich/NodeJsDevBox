#!/bin/bash
set -uex

export PUPPET_ENV=development
export PUPPET_HOST=dev
VAGRANT_LOG=debug
vagrant provision --provision-with shell
