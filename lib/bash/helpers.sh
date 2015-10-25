#!/bin/bash
#
# To be used with bash based charms on Ubuntu 14.04 LTS.
#
set -uex
# Installs given package
# Expects one argument: package-name
# installPackage "puppet" will install Puppet
# Overwrites any existing configuration files(s)
# see: https://bugs.launchpad.net/ubuntu/+source/dpkg/+bug/92265/comments/4
function installPackage {
  local package="${1}"
  local exitcode=0
  DEBIAN_FRONTEND=noninteractive bash -c "apt-get -qq -o Dpkg::Options::='--force-confnew' -y install ${package}" >/dev/null  || exitcode=$?
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
    echo "Purging old ${package} installation"
    apt-get purge "${package}" --yes
    apt-get autoremove --yes
  # if return code is not 33 exit with that code
  elif [ "33" -ne "${exitcode}" ]; then
    exit ${exitcode}
  fi
}

# Downloads file in given remote path into given local path
# Expects three arguments: remotepath, localpath, filename
# downloadFile downloadFile https://foohub.com/user/module/archive \
# /home/user/tmp "foohub-1.0.1.tar.gz" willd download file foohub-1.0.1.tar.gz
# from https://foohub.com/user/module/archive to /home/user/tmp
function downloadFile {
  local remotepath="${1:-notdefined}"
  local localpath="${2:-notdefined}"
  local filename="${3:-notdefined}"
  if [ ! -f "${localpath}/${filename}" ]; then
    wget "${remotepath}/${filename}" --output-document="${localpath}/${filename}"
  fi
}

function puppetApply {
#  local DIR="${BASH_SOURCE%/*}"
#  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

  local manifestpath="${1:-}"
  local options="${2:-'--debug --verbose'}"

  if [[ -z "${manifestpath// }" ]];
  then
    echo "Could not run puppet apply. Empty manifest path given";
    exit 1;
  fi

  puppet apply ${options} "${manifestpath}"
}

# Installs Puppet module
# Expects two arguments: module, options
# The first parameter, module, is mandatory the second one is optional
# $module holds module name in "forge" format e.g. <USERNAME>-<MODULE NAME>
# see https://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html#a-note-on-module-names
# or path to local release tarball
# see https://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html#installing-from-a-release-tarball
# $options holds available 'puppet install module' command options
# https://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html#installing-modules-1
function installPuppetModule {
  local module="${1}"
  local options="${2:-}"
  local exitcode=0
  # removing trailing space
  # http://stackoverflow.com/a/3232433
  local command=$(echo "${module}" "${options}" | sed 's/[[:space:]]*\$//g')
  puppet module install ${command} || exitcode=$?
  if [ "0" -eq  "${exitcode}" ]; then
    echo "Successfully installed module ${module}"
  else
    echo "Failed to install module ${module}"
    exit ${exitcode}
  fi
}

function uninstallPuppetModule {
  local module="${1}"
  local exitcode=0

  puppet module uninstall ${module} || exitcode=$?
  if [ "0" -eq  "${exitcode}" ]; then
    echo "Successfully uninstalled module ${module}"
  else
    echo "Failed to uninstall module ${module} with exit code ${exitcode}. Module was not installed most likely"
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

function startUpstartJob {
  local job="${1:-none}"
  local exitcode=0
  local job_status=0

  job_status=$(status ${job}) || exitcode=$?
  if [ "0" -ne "${exitcode}" ]
  then
    echo "Unknown job: ${job}"
    exit ${exitcode}
  fi;

  if [[ ${job_status} == *running* ]]
  then
    restart ${job} || exitcode=$?
    if [ "0" -eq "${exitcode}" ]
    then
      echo "Successfully restarted ${job}";
    else
      echo "Failed to restart ${job}"
      exit ${exitcode}
    fi;
  else
    start ${job} || exitcode=$?
    if [ "0" -eq "${exitcode}" ]
    then
      echo "Successfully started ${job}"
    else
      echo "Failed to start ${job}"
      exit ${exitcode}
    fi
  fi
}

function stopUpstartJob {
  local job="${1:-none}"
  local exitcode=0
  local job_status=0

  job_status=$(status ${job}) || exitcode=$?
  if [ "0" -ne "${exitcode}" ]
  then
    echo "Unknown job: ${job}"
    exit ${exitcode}
  fi;

  if [[ ${job_status} == *waiting* ]]
  then
      echo "Job ${job} is already stopped";
  else
    stop ${job} || exitcode=$?
    if [ "0" -eq "${exitcode}" ]
    then
      echo "Successfully stopped ${job}"
    else
      echo "Failed to stop ${job}"
      exit ${exitcode}
    fi
  fi
}


function idempotentInstall {
  local package="${1}"
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
    installPackage ${package}
  fi
}

# Downloads and install Debian package provided by PuppetLabs
function installPuppetDeb {
  idempotentInstall 'wget'
  local DISTRIB_CODENAME=$(lsb_release --codename --short)
  local REPO_DEB_URL=$(printf "${1}" ${DISTRIB_CODENAME})
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

function idempotentInstallPuppet {
  local pin="${1:-3.7.3}"
  local puppet_repo="${2}"
  local package="puppet"
  local test=0

  dpkg --compare-versions $(puppet --version) ge ${pin} || test=$?
  if [[ "0" -ne "${test}" ]]; then
    purgePackage ${package}
    purgePuppetDeb
    installPuppetDeb "${puppet_repo}"
    apt-get update --quiet
    installPackage ${package}
  else
    echo "Puppet already at version ${pin}"
  fi
}

function removeAlternatives {
  local version="${1:-}"
  update-alternatives --remove ruby /usr/bin/ruby${version}
  update-alternatives --remove irb /usr/bin/irb${version}
  update-alternatives --remove gem /usr/bin/gem${version}
  update-alternatives --remove rake /usr/bin/rake${version}
  update-alternatives --remove rdoc /usr/bin/rdoc${version}
  update-alternatives --remove testrb /usr/bin/testrb${version}
  update-alternatives --remove erb /usr/bin/erb${version}
  update-alternatives --remove ri /usr/bin/ri${version}
}

function rubyAlternatives {
  local pin="${1:-2.1.0}"
  version="${pin%.*}"
  removeAlternatives
  removeAlternatives "1.9.1"
  removeAlternatives ${version}
  update-alternatives \
    --install /usr/bin/ruby ruby /usr/bin/ruby${version} 50 \
    --slave /usr/bin/irb irb /usr/bin/irb${version} \
    --slave /usr/bin/gem gem /usr/bin/gem${version} \
    --slave /usr/bin/rake rake /usr/bin/rake${version} \
    --slave /usr/bin/rdoc rdoc /usr/bin/rdoc${version} \
    --slave /usr/bin/testrb testrb /usr/bin/testrb${version} \
    --slave /usr/bin/erb erb /usr/bin/erb${version} \
    --slave /usr/bin/ri ri /usr/bin/ri${version}
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

# http://m0dlx.com/blog/Puppet__could_not_find_a_default_provider_for_augeas.html
# test: echo -e "require 'augeas'\nputs Augeas.open" | ruby -rrubygems
# https://tickets.puppetlabs.com/browse/PUP-3796
function nastyAugeasFix {
  cur_dir=$(pwd)
  cd /usr/lib/x86_64-linux-gnu/ruby/vendor_ruby/
  ver_two_one='2.1.0'
  if ! [ -h "${ver_two_one}" ]
  then
      rm -r "${ver_two_one}/";
      ln -s 2.0.0/ ${ver_two_one}
  fi;
  cd ../../
  if ! [ -h 'libruby-2.0.so.2.0' ]
  then
      ln -s libruby-2.1.so.2.1 libruby-2.0.so.2.0
  fi;
  cd ${cur_dir}
}

function idempotentInstallLibrarianPuppet {
  local test=0
  gem list "librarian-puppet" -i || test=$?

  if [[ "0" -ne $test ]]; then
    gem install librarian-puppet --no-rdoc --no-ri
  else
    echo "gem librarian-puppet already installed"
  fi
}

function idempotentInstallDeepMerge {
  local test=0
  gem list "deep_merge" -i || test=$?

  if [[ "0" -ne $test ]]; then
    gem install deep_merge --no-rdoc --no-ri
  else
    echo "gem deep_merge already installed"
  fi
}
