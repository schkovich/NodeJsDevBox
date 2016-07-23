#!/bin/bash
#
# Set of utility functions needed to install Puppet.
#
set -uex
# Installs given package
# Expects one argument: package-name
# installPackage "puppet" will install Puppet
# Overwrites any existing configuration files(s)
# see: https://bugs.launchpad.net/ubuntu/+source/dpkg/+bug/92265/comments/4
function installPackage {
  local package="${1}"
  local pin="${2:-notdefined}"
  local exitcode=0
  local installCommand="apt-get -qq -o Dpkg::Options::='--force-confnew' -y install ${package}"
  if [ "notdefined" != "${pin}" ]; then
    installCommand+="=${pin}"
  fi

  DEBIAN_FRONTEND=noninteractive bash -c "${installCommand}" >/dev/null  || exitcode=$?

  if [ "0" -eq "${exitcode}" ]; then
    echo "Successfully installed package ${package}";
  else
    # a chance to log the error
    echo "Error ${exitcode} installing package ${package}";
    # exit with the same code
    exit ${exitcode}
  fi
}

# Checks if given package is installed
# Expects one argument: package-name
# isPackageInstalled "puppet" will check if Puppet is installed
# returns 0 case when package is installed otherwise returns 33
# When running with e flag set returning any other code than 0
# will stop execution.
function isPackageInstalled {
  # http://superuser.com/questions/43342/how-can-i-display-the-list-of-all-packages-installed-on-my-debian-system
  if dpkg --get-selections | grep -q "^${1}[[:space:]]*install$" >/dev/null; then
    echo "Package ${1} is already installed.";
    return 0
  else
    echo "Package ${1} is not installed.";
    return 33
  fi
}

# Purges given package
# Expects one argument: package-name
# purgePackage "puppet" will completely remove Puppet installation
function purgePackage {
  local package="${1}"
  local exitcode=0
  isPackageInstalled ${package} || exitcode=$?
  # if package is installed and there was no error
  if [ "0" -eq  "${exitcode}" ]; then
    echo "Purging old ${package} installation."
    apt-get purge "${package}" --yes
    apt-get autoremove --yes
  # if return code is not 33 exit with that code
  elif [ "33" -ne "${exitcode}" ]; then
    exit ${exitcode}
  fi
}

# Creates a directory in the given path
# Makes parent directories as needed
# Exits case empty path is given
function createDirectory {
  local path="${1:-}"
  # http://unix.stackexchange.com/a/146945
  if [[ -z "${path// }" ]];
  then
    echo "Could not create directory. Empty path given";
    exit 1;
  fi
  if [ ! -d ${path} ]
  then
      mkdir -p ${path};
  fi;
}


function idempotentInstall {
  local package="${1}"
  local pin="${2:-notdefined}"
  local test=0
  if [[ -z "${package// }" ]];
  then
    echo "Could not install. No package name given";
    exit 1;
  fi
  isPackageInstalled ${package} || test=$?
  if [ "0" -ne  "${test}" ]; then
    echo "Installing ${package}"
    apt-get update --quiet
    installPackage "${package}" "${pin}"
  fi
}

# Downloads and install Debian package provided by PuppetLabs
function installPuppetDeb {
  local puppet_repo="${1:-}"
  local distrib_codename=$(lsb_release --codename --short)
  local repo_deb_url=$(printf ${puppet_repo} ${distrib_codename})
  local repo_deb_path=$(mktemp)
  wget -q --output-document="${repo_deb_path}" "${repo_deb_url}"
  dpkg -i "${repo_deb_path}" >/dev/null
  rm "${repo_deb_path}"
}

function purgePuppetDeb {
  local deb_provides="/etc/apt/sources.list.d/puppetlabs.list"
  if [ -e ${deb_provides} ]; then
    dpkg --purge 'puppetlabs-release'
  fi
}

function idempotentInstallPuppet {
  local pin="${1:-}"
  local puppet_repo="${2:-}"
  local package="puppet-agent"
  local test=0

  if [[ -z "${puppet_repo// }" ]];
  then
    echo "Could not install Puppet. Empty repostiro string given";
    exit 1;
  fi

  dpkg --compare-versions $(puppet-agent --version) ge ${pin} || test=$?
  if [[ "0" -ne "${test}" ]]; then
    purgePackage ${package}
    rm -rf /etc/puppet
    purgePuppetDeb
    installPuppetDeb "${puppet_repo}"
    apt-get update --quiet
    installPackage ${package} ${pin}
    # see  https://docs.puppetlabs.com/puppet/4.3/reference/whered_it_go.html#nix-executables-are-in-optpuppetlabsbin
    cd /usr/bin
    if ! [ -L "puppet" ]; then
      ln -s /opt/puppetlabs/bin/puppet
    fi
    if ! [ -f "hiera" ]; then
      ln -s /opt/puppetlabs/bin/hiera
    fi
    if ! [ -L "facter" ]; then
      ln -s /opt/puppetlabs/bin/facter
    fi
    if ! [ -L "mco" ]; then
      ln -s /opt/puppetlabs/bin/mco
    fi
  else
    echo "Puppet agent is already at version ${pin}"
  fi
}

# Installs given Ruby version
function installRuby {
  local version="${1:-2.1.0}"
  apt-add-repository --yes ppa:brightbox/ruby-ng
  apt-get update --quiet
  # http://stackoverflow.com/a/4170409
  installPackage "ruby${version%.*}"
  installPackage "ruby${version%.*}-dev"
}

# Installs required Ruby version case it is not already installed
function idempotentInstallRuby {
  local pin="${1:-2.1.0}"
  local test=0
  isPackageInstalled "ruby${pin%.*}" || test=$?
  if [ "0" -ne  "${test}" ]; then
    installRuby ${pin}
  else
    dpkg --compare-versions $(ruby -e 'puts "#{RUBY_VERSION}"') ge ${pin} || test=$?
    if [[ "0" -ne "${test}" ]]; then
      installRuby ${pin}
    else
      echo "Ruby already at or greater than version ${pin}"
    fi
  fi
}

function idempotentInstallLibrarianPuppet {
  local test=0
  gem list "librarian-puppet" -i || test=$?

  if [[ "0" -ne $test ]]; then
    gem install librarian-puppet --no-rdoc --no-ri
  else
    echo "gem librarian-puppet alreary installed"
  fi
}

function idempotentInstallDeepMerge {
  local test=0
  gem list "deep_merge" -i || test=$?

  if [[ "0" -ne $test ]]; then
    gem install deep_merge --no-rdoc --no-ri
  else
    echo "gem deep_merge alreary installed"
  fi
}
