# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))
data = YAML.load_file("#{dir}/lolstats.yaml")
config = data['vagrantfile-config']

case
  when !config['vm']['chosen_provider'].nil?
    provider_name = config['vm']['chosen_provider']
  when !"#{ENV['VAGRANT_DEFAULT_PROVIDER']}".empty?
    provider_name = "#{ENV['VAGRANT_DEFAULT_PROVIDER']}"
  else
    provider_name = 'virtualbox'
end
provider = config['vm']['providers'][provider_name]
shell = config['vm']['provision']['shell']
puppet = config['vm']['provision']['puppet']
network = config['vm']['providers'][provider_name]['network']
synced_folder = config['vm']['synced_folder'];
ssh = config['ssh']
Vagrant.require_version config['vagrant']['require_version']

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "#{provider['box']}"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  if provider['box_url'].to_s.strip.length != 0
    config.vm.box_url = "#{provider['box_url']}"
  end

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
  if provider['host'].to_s.strip.length != 0 && provider['domain'].to_s.strip.length != 0
    hostname = "#{provider['host']}.#{provider['domain']}"
  end

  if provider_name == 'virtualbox'
    config.vm.provider :virtualbox do |vb|
      provider['modifyvm'].each do |key, value|
        vb.customize ['modifyvm', :id, "--#{key}", "#{value}"]
      end
    end
  end
  # kvm provider
  if provider_name == 'kvm'
      config.vm.provider :kvm do |vm|
        vm.memory_size = "#{provider['memory_size']}"
        vm.core_number = "#{provider['core_number']}"
      end
  end

  unless hostname.nil? && hostname.to_s.strip.length == 0
    config.vm.hostname = hostname
  end

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
  if network['private_network']['type']
    config.vm.network "private_network", type: network['private_network']['type']
  elsif network['private_network']['ip']
    config.vm.network "private_network", ip: network['private_network']['ip']
  end

  synced_folder.each do |key, folder|
    unless folder['source'].empty? || folder['target'].empty?
      sync_owner = !folder['sync_owner'].nil? ? folder['sync_owner'] : 'vagrant'
      sync_group = !folder['sync_group'].nil? ? folder['sync_group'] : 'vagrant'
      config.vm.synced_folder "#{folder['source']}", "#{folder['target']}",
      group: "#{sync_group}", owner: "#{sync_owner}", mount_options: folder['mount_options']
    end
  end
  # Working directory
  wdir = "#{provider['wdir']}"
  # Shell provision
  config.vm.provision  "install_puppet", type: "shell", run: "once" do |s|
    args = shell['args']['install_puppet']
    s.inline = "/bin/bash /srv/lolstats/#{shell['config_puppet']} $1 $2 $3 $4"
    s.args = "#{args['ruby_version']} #{args['puppet_version']} #{args['puppet_repo']} #{shell['helpers']}"
    unless shell['privileged'].nil?
      s.privileged = shell['privileged']
    end
  end

  config.vm.provision "config_puppet", type: "shell", run: "always" do |i|
    args = shell['args']['config_puppet']
    i.inline = "/bin/bash /srv/lolstats/#{shell['config_puppet']} $1 $2 $3 $4 $5"
    i.args = "#{wdir} #{args['sync_dir']} #{shell['helpers']} #{args['exclude_path']} #{provider_name}"
    unless shell['privileged'].nil?
      i.privileged = shell['privileged']
    end
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
      "--modulepath=" + wdir.to_s + puppet['module_path'].join(":" + wdir.to_s)
    ]
    if !puppet['options'].empty?
      puppet_options.concat(puppet['options'])
    end
    p.options = puppet_options
  end
end
