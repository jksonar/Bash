#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
CONSUL_VERSION="1.20.1"
CONSUL_USER="consul"
CONSUL_GROUP="consul"
BIND_ADDRESS="192.168.56.108"
NODE_NAME="redhat9"
DATACENTER="server1"

installConsul() {
    echo "Downloading and installing Consul..."
    cd /tmp
    wget -q https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
    unzip -q consul_${CONSUL_VERSION}_linux_amd64.zip
    mv consul /usr/local/bin/

    if [ ! -f /usr/local/bin/consul ]; then
        echo "Consul binary not found. Exiting..."
        exit 1
    fi

    /usr/local/bin/consul --version
}

createUsersAndGroup() {
    echo "Creating Consul user and directories..."
    groupadd --system $CONSUL_GROUP || true
    useradd -s /sbin/nologin --system -g $CONSUL_GROUP $CONSUL_USER || true
    mkdir -p /var/lib/consul /etc/consul.d
    chown -R $CONSUL_USER:$CONSUL_GROUP /var/lib/consul /etc/consul.d
    chmod -R 775 /var/lib/consul
}

createService() {
    echo "Creating systemd service for Consul..."
    cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Service Discovery Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CONSUL_USER
Group=$CONSUL_GROUP
ExecStart=/usr/local/bin/consul agent -server -ui \
            -advertise=$BIND_ADDRESS \
            -bind=$BIND_ADDRESS \
            -data-dir=/var/lib/consul \
            -node=consul-01 \
            -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start consul
    systemctl enable consul
}

createJsonConfig() {
    echo "Creating Consul configuration..."
    ENCRYPT_KEY=$(/usr/local/bin/consul keygen)
    cat <<EOF > /etc/consul.d/config.json
{
  "bootstrap": true,
  "server": true,
  "log_level": "DEBUG",
  "enable_syslog": true,
  "datacenter": "$DATACENTER",
  "addresses": {
    "http": "0.0.0.0"
  },
  "bind_addr": "$BIND_ADDRESS",
  "node_name": "$NODE_NAME",
  "data_dir": "/var/lib/consul",
  "acl_datacenter": "$DATACENTER",
  "acl_default_policy": "allow",
  "encrypt": "$ENCRYPT_KEY"
}
EOF

    systemctl restart consul
}

configureNginx() {
    echo "Configuring Nginx for Consul UI..."
cat <<EOF > /etc/nginx/conf.d/consul.conf
server {
    listen 80;
    server_name $BIND_ADDRESS;
    root /var/lib/consul;

    location / {
        proxy_pass http://127.0.0.1:8500;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
    }
}
EOF

    nginx -t
    systemctl restart nginx
    systemctl enable nginx
}

verifyServices() {
    echo "Verifying Consul and Nginx services..."
    systemctl status consul || echo "Consul service failed to start."
    systemctl status nginx || echo "Nginx service failed to start."
    echo "Consul UI available at http://$BIND_ADDRESS"
}

main() {
    echo "Installing necessary packages..."
    yum install -y unzip gnupg2 curl wget nginx

    installConsul
    createUsersAndGroup
    createService
    createJsonConfig
    configureNginx
    verifyServices
}

main