#!/bin/bash
set -uex

#DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi
source "/vagrant/lib/bash/helpers.sh"

# See http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
#locale-gen en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#sudo dpkg-reconfigure locales

function installPuppetDeb {
  installWget
  local DISTRIB_CODENAME=$(lsb_release --codename --short)
  local REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
  local REPO_DEB_PATH=$(mktemp)
  wget -q --output-document="${REPO_DEB_PATH}" "${REPO_DEB_URL}"
  dpkg -i "${REPO_DEB_PATH}" >/dev/null
}

function purgePuppetDeb {
  local DEB_PROVIDES="/etc/apt/sources.list.d/puppetlabs.list"
  if [ -e ${DEB_PROVIDES} ]; then
    dpkg --purge 'puppetlabs-release'
  fi
}

function installPuppet {
  local package="puppet"
  purgePackage ${package}
  purgePuppetDeb
  installPuppetDeb
  apt-get update >/dev/null
  installPackage ${package}
}

installPuppet
