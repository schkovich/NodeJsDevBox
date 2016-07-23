# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))
data = YAML.load_file("#{dir}/lolstats.yaml")
config = data['vagrantfile-config']

if config['vm']['chosen_provider'].to_s == ''
  provider_name = ENV['VAGRANT_DEFAULT_PROVIDER'] || 'virtualbox'
else
  provider_name = config['vm']['chosen_provider']
end

ENV['VAGRANT_DEFAULT_PROVIDER'] = provider_name

provider = config['vm']['providers'][provider_name]
shell = config['vm']['provision']['shell']
puppet = config['vm']['provision']['puppet']
network = config['vm']['providers'][provider_name]['network']
sync_paths = config['vm']['sync_paths'];
ssh = config['ssh']
Vagrant.require_version config['vagrant']['require_version']

# IaC directory
iac_path = "#{config['iac_path']}"
env_path = "#{config['env_path']}/environments/#{provider['environment']}"

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

  # setup FQDN
  # will add to /etc/hosts 127.0.1.1 dev.node.js dev case when $PUPPET_HOST is dev
  # for details see http://linux.die.net/man/1/hostname
  # https://docs.puppetlabs.com/facter/1.6/core_facts.html#domain
  # config.vm.hostname = "#{provider['host']}.#{provider['domain']}"
  if provider['host'].to_s.strip.length > 0 && provider['domain'].to_s.strip.length > 0
    config.vm.hostname = "#{provider['host']}.#{provider['domain']}"
  end

  # View the documentation for the provider you're using for more
  # information on available options.
  if provider_name == 'virtualbox'
    config.vm.provider :virtualbox do |vb|
      provider['modifyvm'].each do |key, value|
        vb.customize ['modifyvm', :id, "--#{key}", "#{value}"]
      end
    end
  end

  # libvirt provider
  if provider_name == 'libvirt'
    config.vm.provider :libvirt do |domain|
      provider['modifyvm'].each do |key, value|
        domain.send("#{key}=", value)
      end
    end
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

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # NFS shares (Ubuntu) are not working well on encrypted file systems
  # https://help.ubuntu.com/community/SettingUpNFSHowTo#Mounting_NFS_shares_in_encrypted_home_won.27t_work_on_boot
  sync_paths.each do |key, folder|
    unless folder['source'].empty? || folder['target'].empty?
      sync_owner = !folder['sync_owner'].nil? ? folder['sync_owner'] : 'vagrant'
      sync_group = !folder['sync_group'].nil? ? folder['sync_group'] : 'vagrant'
      config.vm.synced_folder "#{folder['source']}", "#{iac_path}/#{folder['target']}",
      group: "#{sync_group}", owner: "#{sync_owner}", mount_options: folder['mount_options'],
      type: "#{provider['sync_type']}", rsync__args: ["--verbose", "--archive", "--delete", "-z", "--links"]
    end
  end

  # Shell provision
  args_install = shell['args']['install_puppet']
  config.vm.provision  "install_puppet", type: "shell", run: "once" do |s|
    s.path = "#{shell['install_puppet']}"
    s.upload_path = "#{iac_path}/#{shell['install_puppet']}"
    s.args = "#{iac_path}/#{shell['helpers']} #{args_install['ruby_version']} #{args_install['puppet_version']} #{args_install['puppet_repo']}"
    unless shell['privileged'].nil?
      s.privileged = shell['privileged']
    end
  end

  config.vm.provision "config_puppet", type: "shell", run: "always" do |i|
    args = shell['args']['config_puppet']
    i.args = "#{env_path}"
    i.path = "#{shell['config_puppet']}"
    unless shell['privileged'].nil?
      i.privileged = shell['privileged']
    end
  end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to defined working directory.
  config.vm.provision :puppet do |p|
    p.environment_path = "lib/puppet"
    p.temp_dir = '/etc/puppetlabs/code'
    p.environment = provider['environment'].to_s
    p.synced_folder_args = ["--verbose", "--archive", "--delete", "-z", "--links",
        "--exclude=development/vendors", "--exclude=*production", "--exclude=*.lock"]
    p.facter = {
      "puppet_home" => "#{provider['home']}",
      "puppet_user" => "#{provider['ssh']['username']}",
      "monogo_dbname" => "#{puppet['facts']['mongodb']['dbname']}",
      "monogo_dbuser" => "#{puppet['facts']['mongodb']['dbuser']}",
      "monogo_password" => "#{puppet['facts']['mongodb']['password']}",
      "mongo_dbadmin" => "#{puppet['facts']['mongodb']['dbadmin']}",
      "mongo_admin_password" => "#{puppet['facts']['mongodb']['admin_password']}"
    }
    p.hiera_config_path = "lib/puppet/hiera.yaml"
    p.working_directory = "/etc/puppetlabs/code/environments"
    p.options = puppet['options']
  end
end
