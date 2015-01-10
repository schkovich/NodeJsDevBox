# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))
data = YAML.load_file("#{dir}/../wpvatrates.yaml")
config = data['vagrantfile-config']
if "#{ENV['VAGRANT_DEFAULT_PROVIDER']}".empty?
  provider_name = 'virtualbox'
else
  provider_name = "#{ENV['VAGRANT_DEFAULT_PROVIDER']}"
end

Vagrant.require_version '>= 1.7.0'

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = config['vm']['provider'][provider_name]['box'].to_s

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
  config.vm.hostname = config['vm']['provider'][provider_name]['host'] + "."
    config['vm']['provider'][provider_name]['domain']

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    # vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", config['vm']['provider'][provider_name]['memory_size']]
    # https://www.virtualbox.org/manual/ch09.html#nat-adv-dns
    # http://www.tcpipguide.com/free/t_DHCPLeaseReallocationProcess.htm
    # Expired DHCP lease can cause no Internet connectivity from guest
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # kvm provider
  config.vm.provider "kvm" do |v|
    v.memory_size = config['vm']['provider'][provider_name]['memory_size']
    v.core_number = config['vm']['provider'][provider_name]['core_number']
  end

  # aws provider
  config.vm.provider :aws do |aws, override|

    aws.access_key_id = "#{config['vm']['provider']['aws']['access_key_id']}"
    aws.secret_access_key = "#{config['vm']['provider']['aws']['secret_access_key']}"
    aws.keypair_name = "#{config['vm']['provider']['aws']['keypair_name']}""
    aws.ami = "#{config['vm']['provider']['aws']['ami']}"
    aws.instance_type = config['vm']['provider']['aws']['instance_type']
    aws.security_groups = ['default']
    override.ssh.username = config['vm']['provider'][provider_name]['ssh']['username']
    override.ssh.private_key_path = "#{config['ssh']['private_key_path']}"

    if !config['vm']['provider']['aws']['region'].nil?
      aws.region = "#{config['vm']['provider']['aws']['region']}"
    end

    if !config['vm']['provider']['aws']['security_groups'].nil? && !config['vm']['provider']['aws']['security_groups'].empty?
      aws.security_groups = config['vm']['provider']['aws']['security_groups']
    end

    aws.tags = {}
    config['vm']['provider']['aws']['tags'].each do |key, tag|
      aws.tags.store(:key, tag)
    end

    aws.region_config "#{config['vm']['provider'][provider_name]['region']}" do |region|
      # ubuntu server 14.04 LTS in Ireland
      # region.ami = "ami-2ebd1f59"
      # region.keypair_name = ""

      # region.subnet_id = ''
      # region.security_groups = []
    end
  end

  # Working directory
  wdir = config['vm']['provider'][provider_name]['wdir']
  # Shell provision
  config.vm.provision :shell do |s|
    s.args = wdir
    s.path = config['vm']['provision']['shell']['script_path'].to_s
  end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to defined working directory.
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = ["vm", wdir]
    puppet.manifest_file  = config['vm']['provision']['puppet']['manifest_file'].to_s
    puppet.facter = {
      "puppet_wdir" => wdir,
      "puppet_home" => config['vm']['provider'][provider_name]['home'],
      "puppet_user" => config['vm']['provider'][provider_name]['ssh']['username']
    }
    puppet.temp_dir = wdir
    puppet_options = [
      "--environment=" + config['vm']['provider'][provider_name]['environment'].to_s,
      "--modulepath=" + wdir.to_s + config['vm']['provision']['puppet']['module_path'].to_s
    ]
    if !config['vm']['provision']['puppet']['options'].empty?
      puppet_options.concat = config['vm']['provision']['puppet']['options']
    end
    puppet.options = puppet_options
  end

end
