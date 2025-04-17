echo "Starting fully automated Zabbix installation..."

System Preparation
echo "System Preparation"
apt-get update
apt-get install -y wget gnupg2 default-mysql-server locales debconf-utils apache2 php8.2 php8.2-mysql php8.2-mbstring php8.2-gd php8.2-xml php8.2-bcmath php8.2-ldap

# Configure locale
sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US:en
echo 'LC_ALL=en_US.UTF-8' >> /etc/environment
echo 'LANG=en_US.UTF-8' >> /etc/environment
echo 'LANGUAGE=en_US:en' >> /etc/environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

# Install Zabbix Components
echo "Installing Zabbix Components"
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-1+debian12_all.deb
dpkg -i zabbix-release_7.0-1+debian12_all.deb
apt-get update
apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Database Setup
echo "Database Configuration"
mysql -e "CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
mysql -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'zabbix'"
mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost'"
mysql -e "FLUSH PRIVILEGES"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -pzabbix zabbix

# Zabbix Server Configuration
echo "Zabbix Server Setup"
cat > /etc/zabbix/zabbix_server.conf <<EOL
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
SocketDir=/var/run/zabbix
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
FpingLocation=/usr/bin/fping
LogSlowQueries=3000
StatsAllowedIP=127.0.0.1
EOL

chown zabbix:zabbix /etc/zabbix/zabbix_server.conf
chmod 640 /etc/zabbix/zabbix_server.conf

# Web Interface Setup
echo "Web Interface Setup"
cat > /etc/apache2/sites-available/zabbix.conf <<EOL
<VirtualHost *:80>
    ServerName zabbix.local
    DocumentRoot /usr/share/zabbix

    <Directory /usr/share/zabbix>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOL

a2ensite zabbix.conf
a2dissite 000-default.conf

cat > /etc/php/8.2/apache2/conf.d/zabbix.ini <<EOL
date.timezone = UTC
max_execution_time = 300
memory_limit = 128M
post_max_size = 16M
upload_max_filesize = 2M
max_input_time = 300
mbstring.func_overload = 0
default_charset = 'UTF-8'
mbstring.internal_encoding = 'UTF-8'
mbstring.language = 'English'
EOL

cat > /usr/share/zabbix/conf/zabbix.conf.php <<EOL
<?php
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'zabbix';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix Server';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOL

chown www-data:www-data /usr/share/zabbix/conf/zabbix.conf.php

# Final Service Setup
echo "Final Configuration"
mkdir -p /etc/systemd/system/zabbix-server.service.d
cat > /etc/systemd/system/zabbix-server.service.d/override.conf <<EOL
[Service]
TimeoutStartSec=300
Restart=on-failure
RestartSec=5s
EOL

mkdir -p /var/run/zabbix
chown zabbix:zabbix /var/run/zabbix
chown -R zabbix:zabbix /var/log/zabbix

# Custom Monitoring Items
echo "=== Adding Custom UserParameters for Service Monitoring ==="
cat >> /etc/zabbix/zabbix_agentd.conf <<EOL

### Custom UserParameters to monitor services ###
UserParameter=service.zabbix,systemctl is-active --quiet zabbix-server && echo 1 || echo 0
UserParameter=service.vault,systemctl is-active --quiet vault && echo 1 || echo 0
UserParameter=service.jenkins,systemctl is-active --quiet jenkins && echo 1 || echo 0
EOL

# Start Services 
echo "=== Starting Services ==="
systemctl daemon-reload
systemctl restart apache2
systemctl enable --now zabbix-server zabbix-agent

echo "Waiting for Zabbix Agent to restart..."
systemctl restart zabbix-agent
sleep 60

# Verification
echo "Verification"
echo "Checking services..."
systemctl status zabbix-server --no-pager | head -n 5

echo ""
echo "Checking database connection..."
mysql -uzabbix -pzabbix zabbix -e "SELECT COUNT(*) FROM users" 2>/dev/null

echo ""
echo "Checking web interface..."
curl -s http://localhost/ | grep -q "Zabbix" && echo "Web interface is ready!" || echo "Web interface check failed"


