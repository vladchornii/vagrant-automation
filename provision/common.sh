# Update system and install common dependencies
apt-get update
apt-get upgrade -y
apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    net-tools \
    jq
