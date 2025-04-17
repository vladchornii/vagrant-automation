# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y openjdk-17-jre jenkins

# Start and enable Jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to initialize
echo "Waiting for Jenkins to start..."
while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
  sleep 5
done

# Get initial admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
JENKINS_URL="http://localhost:8080"
JENKINS_CLI_JAR="/var/lib/jenkins/jenkins-cli.jar"

# Download Jenkins CLI
echo "Downloading Jenkins CLI..."
while [ ! -f $JENKINS_CLI_JAR ]; do
  wget -O $JENKINS_CLI_JAR $JENKINS_URL/jnlpJars/jenkins-cli.jar || sleep 5
done

# Install required plugins
echo "Installing Jenkins plugins..."
java -jar $JENKINS_CLI_JAR -s $JENKINS_URL -auth admin:$JENKINS_PASSWORD install-plugin \
  matrix-auth \
  github \
  workflow-aggregator \
  credentials-binding \
  ssh-slaves \
  -restart

# Wait for Jenkins to restart
echo "Waiting for Jenkins to restart..."
sleep 60

# Create Jenkins admin user
ADMIN_USER="admin"
ADMIN_PASS="admin123" 
ADMIN_EMAIL="admin@example.com"
ADMIN_FULLNAME="Jenkins Administrator"

echo "Creating admin user..."
cat <<EOF | java -jar $JENKINS_CLI_JAR -s $JENKINS_URL -auth admin:$JENKINS_PASSWORD groovy =
import jenkins.model.*
import hudson.security.*
import hudson.util.*
import jenkins.install.*

def instance = Jenkins.getInstance()

// Create the admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("$ADMIN_USER", "$ADMIN_PASS")
instance.setSecurityRealm(hudsonRealm)

// Create the authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

// Disable setup wizard if needed
if (!instance.installState.isSetupComplete()) {
    instance.installState = InstallState.INITIAL_SETUP_COMPLETED
}

// Save configuration
instance.save()
EOF

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

echo "Jenkins setup complete!"
echo "Admin username: $ADMIN_USER"
echo "Admin password: $ADMIN_PASS"
echo "Access Jenkins at: http://jenkins.local:8080"