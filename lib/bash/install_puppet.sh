#!/bin/bash
set -uex
HELPERS="${1:-helpers.sh}"
RUBY_VERSION="${2:-}"
PUPPET_VERSION="${3:-}"
PUPPET_REPO="${4:-}"

source "${HELPERS}"

# See http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
export LANGUAGE=en_GB.UTF-8
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8
locale-gen en_GB en_GB.UTF-8
dpkg-reconfigure --frontend=noninteractive locales

idempotentInstall "software-properties-common"
idempotentInstall "python3-software-properties"
idempotentInstall "build-essential"
idempotentInstall "git"
idempotentInstall "wget"

idempotentInstallRuby "${RUBY_VERSION}"
idempotentInstallPuppet "${PUPPET_VERSION}" "${PUPPET_REPO}"
idempotentInstallLibrarianPuppet
idempotentInstallDeepMerge
