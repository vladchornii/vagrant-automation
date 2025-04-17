Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "devops-vm"
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # Hosts file entries
  config.vm.provision "shell" do |s|
    s.inline = <<-SHELL
      echo "192.168.56.10 vault.local jenkins.local zabbix.local" >> /etc/hosts
    SHELL
  end
  
  # Provisioning scripts
  config.vm.provision "shell", path: "provision/common.sh"
  config.vm.provision "shell", path: "provision/install_vault.sh", privileged: true
  config.vm.provision "shell", path: "provision/install_jenkins.sh"
  config.vm.provision "shell", path: "provision/install_zabbix.sh", privileged: true
  config.vm.provision "shell", path: "provision/zabbix_add_items.sh", privileged: true
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = "2"
  end
end