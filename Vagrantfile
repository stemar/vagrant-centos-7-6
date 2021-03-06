sync_dir = ENV["SYNC_DIR"] || "Code"
port_80 = ENV["PORT_80"] || 8001
port_3306 = ENV["PORT_3306"] || 33061

Vagrant.require_version ">= 2.0.0"
Vagrant.configure("2") do |config|
  config.vm.define "centos-7-6"
  config.vm.box = "bento/centos-7.6" # 64GB HDD
  config.vm.provider "virtualbox" do |vb|
    vb.name = "centos-7-6"
    vb.memory = "3072" # 3GB RAM
    vb.cpus = 1
  end
  # vagrant@centos-7-6
  config.vm.hostname = "centos-7-6"
  # Synchronize projects and vm directories
  config.vm.synced_folder "~/#{sync_dir}", "/home/vagrant/#{sync_dir}", owner: "vagrant", group: "vagrant"
  config.vm.synced_folder "~/vm", "/home/vagrant/vm", owner: "vagrant", group: "vagrant"
  # Disable default dir sync
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Apache: http://localhost:8001
  config.vm.network :forwarded_port, guest: 80, host: port_80 # HTTP
  config.vm.network :forwarded_port, guest: 3306, host: port_3306 # MySQL
  # Copy SSH keys and Git config
  config.vm.provision :file, source: "~/.ssh", destination: "$HOME/.ssh"
  config.vm.provision :file, source: "~/.gitconfig", destination: "$HOME/.gitconfig"
  # Provision bash script
  config.vm.provision :shell, path: "centos-7-6.sh", env: {
    "CONFIG_PATH" => "/home/vagrant/vm/centos-7-6/config",
    "SYNC_DIR" => sync_dir,
    "PORT_80" => port_80
  }
end
