#!/bin/bash
set -uex

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

RUBY_VERSION="${1:-2.1.0}"
PUPPET_VERSION="${2:-3.8.3}"
PUPPET_REPO="${3:-http://apt.puppetlabs.com/puppetlabs-release-%s.deb}"
HELPERS="${4:-${DIR}/helpers.sh}"

source "${DIR}/${HELPERS}"

# See http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
locale-gen en_GB en_GB.UTF-8
export LANGUAGE=en_GB.UTF-8
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8
dpkg-reconfigure locales

idempotentInstall "build-essential"
idempotentInstall "git"

idempotentInstallRuby "${RUBY_VERSION}"
idempotentInstallPuppet "${PUPPET_VERSION}" "${PUPPET_REPO}"
rubyAlternatives "${RUBY_VERSION}"
nastyAugeasFix
idempotentInstallLibrarianPuppet
idempotentInstallDeepMerge
