# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))
data = YAML.load_file("#{dir}/strongloop.yaml")
config = data['vagrantfile-config']
if "#{ENV['VAGRANT_DEFAULT_PROVIDER']}".empty?
  provider_name = 'virtualbox'
else
  provider_name = "#{ENV['VAGRANT_DEFAULT_PROVIDER']}"
end
provider = config['vm']['providers'][provider_name]
shell = config['vm']['provision']['shell']
puppet = config['vm']['provision']['puppet']
Vagrant.require_version '>= 1.7.0'

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "#{provider['box']}"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 5858, host: 8585

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.10.2"
  # config.vm.network :hostonly, ip: "192.168.10.2"
  # config.vm.network "public_network", :bridge => 'en1: Wi-Fi (AirPort)'
  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network", :bridge => 'en1: 802.11 WiFi (wlan0)'

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # NFS shares (Ubuntu) are not working well on encrypted file systems
  # https://help.ubuntu.com/community/SettingUpNFSHowTo#Mounting_NFS_shares_in_encrypted_home_won.27t_work_on_boot
  # config.vm.synced_folder "~/Projects/HatchJs/", "/project", :nfs => true

  # View the documentation for the provider you're using for more
  # information on available options.

  # setup FQDN
  # will add to /etc/hosts 127.0.1.1 dev.node.js dev case when $PUPPET_HOST is dev
  # for details see http://linux.die.net/man/1/hostname
  # https://docs.puppetlabs.com/facter/1.6/core_facts.html#domain
  # config.vm.hostname = "#{provider['host']}.#{provider['domain']}"

  # kvm provider
  config.vm.provider :kvm do |vm|
    vm.memory_size = "#{provider['memory_size']}"
    vm.core_number = "#{provider['core_number']}"
  end
  # Working directory
  wdir = "#{provider['wdir']}"
  # Shell provision
  config.vm.provision :shell do |s|
    s.args = wdir
    s.path = "#{shell['script_path']}"
  end
  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to defined working directory.
  config.vm.provision :puppet do |p|
    p.manifests_path = ["vm", "#{wdir}#{puppet['manifests_path']}"]
    p.manifest_file  = "#{puppet['manifest_file']}"
    p.facter = {
      "puppet_wdir" => wdir,
      "puppet_home" => "#{provider['home']}",
      "puppet_user" => "#{provider['ssh']['username']}",
      "monogo_dbname" => "#{puppet['facts']['mongodb']['dbname']}",
      "monogo_dbuser" => "#{puppet['facts']['mongodb']['dbuser']}",
      "monogo_password" => "#{puppet['facts']['mongodb']['password']}",
      "mongo_dbadmin" => "#{puppet['facts']['mongodb']['dbadmin']}",
      "mongo_admin_password" => "#{puppet['facts']['mongodb']['admin_password']}"
    }
    p.temp_dir = wdir
    puppet_options = [
      "--environment=" + provider['environment'].to_s,
      "--modulepath=" + wdir.to_s + puppet['module_path'].to_s
    ]
    if !puppet['options'].empty?
      puppet_options.concat(puppet['options'])
    end
    p.options = puppet_options
  end
end
