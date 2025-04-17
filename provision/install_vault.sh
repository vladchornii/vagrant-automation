# Install Vault
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y vault

# Create simplified systemd service for dev mode (Bonus points?)
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Dev Server
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Allow firewall port
apt-get install -y ufw
ufw allow 8200/tcp

# Start and enable Vault
systemctl daemon-reload
systemctl enable vault
systemctl start vault

# Export Vault address
echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /etc/profile