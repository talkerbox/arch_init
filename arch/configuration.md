# Full system configuration
Describe the minimal manual configuration for enabling access to git repo with whole configuration scripts and application configs (user creation, adding to groups, git and ssh installation, pull git repo, run config scripts)

## Configure network
```bash
cp /usr/lib/systemd/network/89-ethernet.network.example /etc/systemd/network/89-ethernet.network
systemctl enable systemd-resolved
systemctl start sysdtemd-resolved
systemctl enable systemd-networkd
systemctl start systemd-networkd
```

## Get and run initial system script from public repo
```bash
cd /tmp/
wget https://raw.githubusercontent.com/talkerbox/arch_init/refs/heads/main/arch/init.sh
chmod +x /tmp/init.sh
./init.sh
```

