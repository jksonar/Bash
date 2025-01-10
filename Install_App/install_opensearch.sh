#!/bin/bash

# Define variables
OPENSEARCH_VERSION="2.10.0"
INSTALL_DIR="/opt/opensearch"
CLUSTER_NAME="opensearch-cluster"
NODE_NAME="node-1"   # Change this for each node
NETWORK_HOST="0.0.0.0"
SEED_HOSTS=("node-1-ip" "node-2-ip")   # Replace with actual IPs
MASTER_NODES=("node-1" "node-2")       # Replace with actual node names
JAVA_HOME_PATH="/usr/lib/jvm/java-11-openjdk-amd64"

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl unzip openjdk-11-jdk

# Download and extract OpenSearch
echo "Downloading OpenSearch..."
wget https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz
tar -xzf opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz
sudo mv opensearch-${OPENSEARCH_VERSION} ${INSTALL_DIR}

# Create OpenSearch user and set permissions
echo "Creating OpenSearch user..."
sudo useradd opensearch
sudo chown -R opensearch:opensearch ${INSTALL_DIR}

# Configure OpenSearch
echo "Configuring OpenSearch..."
cat <<EOF | sudo tee ${INSTALL_DIR}/config/opensearch.yml
cluster.name: ${CLUSTER_NAME}
node.name: ${NODE_NAME}
network.host: ${NETWORK_HOST}
discovery.seed_hosts: ${SEED_HOSTS[@]}
cluster.initial_master_nodes: ${MASTER_NODES[@]}
bootstrap.memory_lock: true
EOF

# Configure JVM options
echo "Configuring JVM options..."
cat <<EOF | sudo tee ${INSTALL_DIR}/config/jvm.options
-Xms4g
-Xmx4g
EOF

# Enable memory locking
echo "Enabling memory locking..."
sudo bash -c 'echo "opensearch   -   memlock    unlimited" >> /etc/security/limits.conf'

# Set environment variables
echo "Setting up environment variables..."
echo "export JAVA_HOME=${JAVA_HOME_PATH}" | sudo tee -a /etc/environment
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/environment
source /etc/environment

# Start OpenSearch as opensearch user
echo "Starting OpenSearch..."
sudo -u opensearch bash -c "${INSTALL_DIR}/bin/opensearch &"

# Verify installation
echo "Verifying OpenSearch cluster status..."
sleep 20
curl -X GET "http://localhost:9200/_cluster/health?pretty"

echo "OpenSearch installation and configuration completed!"
