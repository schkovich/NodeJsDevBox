# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "trusty64"

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
  config.vm.hostname = "#{ENV['PUPPET_HOST']}.node.js"

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

    aws.access_key_id = ""
    aws.secret_access_key = ""
    # aws.keypair_name = ""
    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = ""
    # aws.ami = "ami-7747d01e"
    aws.instance_type = 't1.micro'

    aws.region_config "" do |region|
      region.ami = ""
      region.keypair_name = ""

      # region.subnet_id = ''
      region.security_groups = ['']
    end

    aws.tags = {
      'vpc' => "#{ENV['PUPPET_ENV']}",
      'name' => "#{ENV['PUPPET_NODE']}",
      'version' => '',
      'OS' => 'Ubuntu 13.04',
      'nodejs' => '0.11.9'
    }
  end

  # Configure language
  config.vm.provision :shell do |s|
    s.path = "lib/bash/puppet-install.sh"
  end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path = ['modules']
    puppet.options = [
#       "--hiera_config=/etc/puppet/hiera.yaml",
       "--verbose --debug", "--environment=#{ENV['PUPPET_ENV']}",
#        "--fileserverconfig=/vagrant/fileserver.conf"
       ]
  end

end
