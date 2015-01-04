#!/bin/bash
set -uex

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

source "./lib/bash/env_variables.sh"

vagrant provision --provision-with shell
