projects_path = ENV["PROJECTS_PATH"] || "projects"
Vagrant.require_version ">= 2.0.0"
Vagrant.configure("2") do |config|
  config.vm.define "centos-7-6"
  config.vm.box = "bento/centos-7.6" # 64GB HDD
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072" # 3GB RAM
    vb.cpus = 1
  end
  # vagrant@ubuntu-18-04
  config.vm.hostname = "centos-7-6"
  # Synchronize projects and vm directories
  config.vm.synced_folder "~/#{projects_path}", "/home/vagrant/#{projects_path}", owner: "vagrant", group: "vagrant"
  config.vm.synced_folder "~/vm", "/home/vagrant/vm", owner: "vagrant", group: "vagrant"
  # Disable default dir sync
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Apache: http://localhost:8001
  config.vm.network :forwarded_port, guest: 80, host: 8001 # HTTP
  config.vm.network :forwarded_port, guest: 3306, host: 33061 # MySQL
  # Copy SSH keys and Git config
  config.vm.provision :file, source: "~/.ssh", destination: "$HOME/.ssh"
  config.vm.provision :file, source: "~/.gitconfig", destination: "$HOME/.gitconfig"
  # Provision bash script
  config.vm.provision :shell, path: "centos-7-6.sh", env: {
    "CONFIG_PATH"   => "/home/vagrant/vm/centos-7-6/config",
    "PROJECTS_PATH" => projects_path
  }
end
