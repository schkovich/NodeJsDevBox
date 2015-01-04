#!/bin/bash
set -uex

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

PUPPET_WDIR="${1:-/home/vagrant/opt/puppet}"

source "/vagrant/lib/bash/helpers.sh"

# See http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
#locale-gen en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#dpkg-reconfigure locales

function installPuppetDeb {
  installWget
  local DISTRIB_CODENAME=$(lsb_release --codename --short)
  local REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
  local REPO_DEB_PATH=$(mktemp)
  wget -q --output-document="${REPO_DEB_PATH}" "${REPO_DEB_URL}"
  dpkg -i "${REPO_DEB_PATH}" >/dev/null
  rm "${REPO_DEB_PATH}"
}

function purgePuppetDeb {
  local DEB_PROVIDES="/etc/apt/sources.list.d/puppetlabs.list"
  if [ -e ${DEB_PROVIDES} ]; then
    dpkg --purge 'puppetlabs-release'
  fi
}

function installPuppet {
  local pin="${1-:3.7.3}"
  local package="puppet"
  dpkg --compare-versions $(puppet --version) ge ${pin}
  ver=$?
  if [[ "0" -ne "${ver}" ]]; then
    purgePackage ${package}
    purgePuppetDeb
    installPuppetDeb
    apt-get update >/dev/null
    installPackage ${package}
  else
    echo "Puppet already at version ${pin}"
  fi
}

function installRuby {
  apt-add-repository --yes ppa:brightbox/ruby-ng
  apt-get update >/dev/null
  installPackage "ruby2.1"
  installPackage "ruby2.1-dev"
}

function idempotentInstallRuby {
  local pin="${1-:2.1.0}"
  local test=0
  isPackageInstalled "ruby2.1" || test=$?
  if [ "0" -ne  "${test}" ]; then
    installRuby
  else
    dpkg --compare-versions $(ruby -e 'puts "#{RUBY_VERSION}"') ge ${pin}
    ver=$?
    if [[ "0" -ne "${ver}" ]]; then
      installRuby
    else
      echo "Ruby already at or greater than version ${pin}"
    fi
  fi
}

function installLibrarianPuppet {
  local test=0
  gem list "librarian-puppet" -i || test=$?

  if [[ "0" -ne $test ]]; then
    gem install librarian-puppet
  else
    echo "gem librarian-puppet alreary installed"
  fi
}

idempotentInstall "build-essential"
idempotentInstall "git"
installPuppet
idempotentInstallRuby
installLibrarianPuppet

createDirectory "${PUPPET_WDIR}"
cwd=$(pwd)
cd "${PUPPET_WDIR}"
rsync  -avh --no-compress --progress --delete  --exclude .git/ --exclude .idea/ --exclude .vagrant/ /vagrant/ .
createDirectory "${PUPPET_WDIR}/modules"
librarian-puppet update --verbose
cd ${cwd}
