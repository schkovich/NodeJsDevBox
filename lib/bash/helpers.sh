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
    echo "Purging old ${package} installation at ${JUJU_REMOTE_UNIT:-unset}"
    apt-get purge "${package}" --yes
    apt-get autoremove --yes
  # if return code is not 33 exit with that code
  elif [ "33" -ne "${exitcode}" ]; then
    exit ${exitcode}
  fi
}

function installWget {
  # Install wget if we have to (some older Ubuntu versions)
  local package='wget'
  local test=0
  isPackageInstalled ${package} || test=$?
  if [ "0" -ne  "${test}" ]; then
    echo "Installing ${package} at ${JUJU_REMOTE_UNIT:-unset}"
    apt-get update >/dev/null
    installPackage ${package}
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

# Tests if puppet agent is connecting to the puppet master server
function testPuppetAgent {
  local exitcode=0
  local external_puppetmaster=$(config-get external-puppetmaster)
  puppet agent --test || exitcode=$?
  if [ "0" -eq "${exitcode}" ]; then
    echo "Successfully tested puppet agent connecting to ${external_puppetmaster}";
  else
    echo "Puppet agent failed to connect to ${external_puppetmaster}";
    exit ${exitcode}
  fi
}

function puppetApply {
  local DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  local manifestpath=$(config-get "manifest-path")

  puppet apply --debug --verbose "${DIR}/../../${manifestpath:-}"
}

# Tests if puppet apply runs as expected
function testPuppetApply {
  local DIR="${BASH_SOURCE%/*}"
  if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
  local exitcode=0
  puppet apply --test "${DIR}/../lib/puppet/test.pp" || exitcode=$?
  if [ "0" -eq "${exitcode}" ]; then
    echo "Successfully tested puppet apply";
  else
    echo "Failed to run puppet apply";
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

function createRelationConfigDirectory {
  local path="/usr/local/charm-relations/${JUJU_UNIT_NAME}"
  createDirectory ${path}
}

function removeRelationConfigDirectory {
  local path="/usr/local/charm-relations/${JUJU_UNIT_NAME}"
  rm -rf ${path} || exitcode=$?
}

function readRelationConfigs {
  local path="/usr/local/charm-relations/${JUJU_UNIT_NAME}"
  for f in ${path}
  do
    if ! [ -d ${f} ]
    then
      # take action on each file. $f store current file path
      . ${f}
    fi
  done
}
