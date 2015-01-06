# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "aws-nodejs"
  # KVM box name
  # config.vm.box = "trusty64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
#   config.vm.network :forwarded_port, guest: 5858, host: 8585

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.10.2"
#   config.vm.network :hostonly, ip: "192.168.10.2"
#   config.vm.network "public_network", :bridge => 'en1: Wi-Fi (AirPort)'
  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
#   config.vm.network "public_network", :bridge => 'en1: 802.11 WiFi (wlan0)'

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
  config.vm.hostname = "#{ENV['PUPPET_HOST']}.#{ENV['PUPPET_DOMAIN']}"

  # config.ssh.username = "ubuntu"
  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    # vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    # https://www.virtualbox.org/manual/ch09.html#nat-adv-dns
    # http://www.tcpipguide.com/free/t_DHCPLeaseReallocationProcess.htm
    # Expired DHCP lease can cause no Internet connectivity from guest
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # kvm provider
  config.vm.provider "kvm" do |v|
    v.memory_size = 2097152
    v.core_number = 2
  end

  # aws provider
  config.vm.provider :aws do |aws, override|

    aws.access_key_id = "AKIAJKG272VJ5HVH4WEQ"
    aws.secret_access_key = "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"
    aws.keypair_name = "goran-aws"
    aws.ami = "ami-2ebd1f59"
    aws.instance_type = 't1.micro'
    aws.security_groups = ['default']
    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "~/.ssh/goran-aws.pem"

    aws.region = "eu-west-1"
    aws.region_config "" do |region|
      # ubuntu server 14.04 LTS in Ireland
      # region.ami = "ami-2ebd1f59"
      # region.keypair_name = "goran-aws"

      # region.subnet_id = ''
      # region.security_groups = ['default']
    end

    aws.tags = {
      'vpc' => "#{ENV['PUPPET_ENV']}",
      'name' => "#{ENV['PUPPET_NODE']}.#{ENV['PUPPET_DOMAIN']}",
      'version' => '0.0.1',
      'OS' => 'Ubuntu 14.04',
      'nodejs' => '0.10.33'
    }
  end

  # Configure language
  config.vm.provision :shell do |s|
    s.args = "#{ENV['PUPPET_WDIR']}"
    s.path = "lib/bash/puppet-install.sh"
  end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = ["vm", "#{ENV['PUPPET_WDIR']}"]
    puppet.manifest_file  = "./manifests/default.pp"
    puppet.facter = {
      "puppet_wdir" => "#{ENV['PUPPET_WDIR']}",
      "puppet_home" => "#{ENV['PUPPET_HOME']}"
    }
    puppet.temp_dir = "#{ENV['PUPPET_WDIR']}"
#    puppet.module_path = ['modules']
    puppet.options = [
#       "--hiera_config=/etc/puppet/hiera.yaml",
       "--verbose --debug", "--environment=#{ENV['PUPPET_ENV']}",
       "--modulepath #{ENV['PUPPET_WDIR']}/modules",
       ]
  end

end
