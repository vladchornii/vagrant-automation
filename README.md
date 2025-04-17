# vagrant-automation
Zabbix + Vault + Jenkins on a single VM via Vagrant

This repository contains a Vagrant configuration that provisions a Debian 12 VM with:
- HashiCorp Vault
- Jenkins
- Zabbix Server

## Prerequisites
- Vagrant
- VirtualBox

# Before Getting Started
## Host Configuration
Add these lines to your host machine's `/etc/hosts` file:

`192.168.56.10 vault.local jenkins.local zabbix.local`

## Jenkins GitHub repository connections
You need to change this part in the script `install_jenkins.sh` file:

```bash
# Configure GitHub credentials (replace values your owns)
echo "Configuring GitHub credentials..."
cat <<EOF | java -jar $JENKINS_CLI_JAR -s $JENKINS_URL -auth admin:$ADMIN_PASS create-credentials-by-xml system::system::jenkins _
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-credentials</id>
  <description>GitHub Credentials</description>
  <username>YOUR_USERNAME_HERE</username>
  <password>YOUR_TOKEN_HERE</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
```

- Change a `<username>` line with your own username on github (you can see it in URL of your profile `https://github.com/YOUR_USERNAME_HERE`

- Change a `<password>>` line with your own GitHub Personal Access Token. You can create new one in `Settings/Developer Settings/Personal access tokens/Tokens (classic)`

# Getting Started
1. Clone this repository
3. Run `vagrant up`
4. Wait for provisioning to complete (may take 15-30 minutes)

# Accessing Services
### Here is accessing services tutorial:

## HashiCorp Vault
- URL: http://vault.local:8200
- Root token: `root`

### Login using `root` token:
<p align="center">
  <img src="https://github.com/user-attachments/assets/cdaa0373-5272-45dd-ba06-11e70baa6a2c" alt="Screenshot" width="1000"/>
</p>

### To write a test secret:
1. Login with the root token
2. Go to the `"Secret Engines"` tab
3. Click `"Enable new engine"` and select `"KV"`
4. Create a path (e.g., `secretpath`)
5. Click `"Create secret"` and enter `key/value` pairs and click `"Save"`

### Now, you can see your secret:
<p align="center">
  <img src="https://github.com/user-attachments/assets/dccad032-50a1-487d-9e5a-6b29b651f2f3" alt="Screenshot" width="1000"/>
</p>

## Jenkins
- URL: http://jenkins.local:8080
- Username: `admin`
- Password: `admin123`

### Login using given credentials:
<p align="center">
  <img src="https://github.com/user-attachments/assets/bb248072-bd08-4711-a66d-f4d93c34fc54" alt="Screenshot" width="1000"/>
</p>

### To create a freestyle job:
1. Login to Jenkins
2. Click `"New Item"`
3. Enter a name and select `"Freestyle project"`
4. In the `"Source Code Management"` section, select `Git`
5. In `Repository URL` input field enter a GitHub repository URL
6. In `Credentionals` select `GitHub Credentials` which automaticly use your own GitHub credentionals
7. Save and build

### Here you can see that bulding is ended by success:
<p align="center">
  <img src="https://github.com/user-attachments/assets/9b535aa8-2281-435c-ad51-9243fb88bc4e" alt="Screenshot" width="1000"/>
</p>

## Zabbix Server
- URL: http://zabbix.local
- Username: `Admin`
- Password: `zabbix`

### Login using given credentials:
<p align="center">
  <img src="https://github.com/user-attachments/assets/874af7f8-d20b-4100-b826-131a78abc0ad" alt="Screenshot" width="1000"/>
</p>

### Zabbix is configured to monitor:
- System metrics (CPU, RAM, disk)
- Service status for:
  - Zabbix Server `service.zabbix`
  - Vault `service.vault`
  - Jenkins `service.jenkins`

### You can check services status on `Monitoring/Hosts/Zabbix Server/Lastest Data` on Zabbix Web UI (active is 1, inactive is 0):
<p align="center">
  <img src="https://github.com/user-attachments/assets/9a2ae876-5e51-42c0-837b-26752f4614ba" alt="Screenshot" width="1000"/>
</p>

### You can check system metrics on `Monitoring/Hosts/Zabbix Server/Dashboards/System performance` on Zabbix Web UI:
<p align="center">
  <img src="https://github.com/user-attachments/assets/a145f67d-edee-428f-9e27-2dbb6a4c4d46" alt="Screenshot" width="1000"/>
</p>

