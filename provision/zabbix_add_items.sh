# Zabbix API Settings
ZBX_URL="http://localhost/zabbix/api_jsonrpc.php"
ZBX_USER="Admin"
ZBX_PASS="zabbix"
HOST_NAME="Zabbix server"  

# Wait until Zabbix API is available
until curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"apiinfo.version","params":[],"id":1}' \
  "$ZBX_URL" | grep -q '"result"'; do
    echo "Waiting for Zabbix API to be available..."
    sleep 5
done

echo "Zabbix API is available!"

# Authenticate and get auth token
AUTH_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
-d '{
    "jsonrpc": "2.0",
    "method": "user.login",
    "params": {
        "username": "'"$ZBX_USER"'",
        "password": "'"$ZBX_PASS"'"
    },
    "id": 1
}' "$ZBX_URL")

AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.result')

if [[ "$AUTH_TOKEN" == "null" || -z "$AUTH_TOKEN" ]]; then
  echo "Failed to get authentication token from Zabbix API."
  exit 1
fi

echo "Authenticated. Token: $AUTH_TOKEN"

# Get Host ID 
HOST_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
-d '{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "filter": {
            "host": ["'"$HOST_NAME"'"]
        }
    },
    "auth": "'"$AUTH_TOKEN"'",
    "id": 2
}' "$ZBX_URL" | jq -r '.result[0].hostid')

if [[ "$HOST_ID" == "null" || -z "$HOST_ID" ]]; then
  echo "Failed to get host ID for '$HOST_NAME'"
  exit 1
fi

echo "Found host ID: $HOST_ID"

# Get Interface ID 
INTERFACE_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
-d '{
    "jsonrpc": "2.0",
    "method": "hostinterface.get",
    "params": {
        "hostids": ["'"$HOST_ID"'"]
    },
    "auth": "'"$AUTH_TOKEN"'",
    "id": 4
}' "$ZBX_URL" | jq -r '.result[0].interfaceid')

if [[ "$INTERFACE_ID" == "null" || -z "$INTERFACE_ID" ]]; then
  echo "Failed to get interface ID for host"
  exit 1
fi

echo "Interface ID: $INTERFACE_ID"

# Define item keys and names 
declare -A ITEMS
ITEMS[service.zabbix]="Zabbix Service"
ITEMS[service.vault]="Vault Service"
ITEMS[service.jenkins]="Jenkins Service"

# Create Items 
for KEY in "${!ITEMS[@]}"; do
  NAME="${ITEMS[$KEY]}"
  echo "Creating item: $NAME ($KEY)"

  curl -s -X POST -H 'Content-Type: application/json' \
  -d '{
      "jsonrpc": "2.0",
      "method": "item.create",
      "params": {
          "name": "'"$NAME"'",
          "key_": "'"$KEY"'",
          "hostid": "'"$HOST_ID"'",
          "type": 0,
          "value_type": 3,
          "interfaceid": "'"$INTERFACE_ID"'",
          "delay": "60s"
      },
      "auth": "'"$AUTH_TOKEN"'",
      "id": 3
  }' "$ZBX_URL" | jq .
done

echo ""
echo "============================================"
echo "Zabbix installation and configuration complete!"
echo "You can now log in to the web interface:"
echo "URL:      http://zabbix.local"
echo "Username: Admin"
echo "Password: zabbix"
echo ""
echo "============================================"