#!/bin/bash

set -e  # Exit on any error
set -u  # Treat unset variables as errors

# Define variables
OPENSEARCH_VERSION="2.18.0"
INSTALL_DIR="/opt/opensearch"
CLUSTER_NAME="opensearch-cluster"
NODE_NAME="node-1"   # Change this for each node
NETWORK_HOST="0.0.0.0"
SEED_HOSTS=("node-1-ip" "node-2-ip")   # Replace with actual IPs
MASTER_NODES=("node-1" "node-2")       # Replace with actual node names
JAVA_HOME_PATH="${INSTALL_DIR}/jdk"
ADMIN_PASSWORD="hADZQ83@u"

# Functions
log_message() {
    echo "[INFO] $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "[ERROR] Command '$1' not found. Please install it."
        exit 1
    fi
}
fix_permissions() {
    log_message "Fixing permissions for OpenSearch configuration..."

    # Set directory permissions
    sudo chmod 0700 "${INSTALL_DIR}/config"

    # Set file permissions for sensitive files
    sudo chmod 0600 "${INSTALL_DIR}/config/"*.pem
    sudo chmod 0600 "${INSTALL_DIR}/config/"*.srl

    # Ensure proper ownership
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}/config"

    log_message "Permissions fixed for OpenSearch configuration."
}

setup_environment(){
# Set environment variables
echo "Setting up environment variables..."
echo "export OPENSEARCH_HOME=${INSTALL_DIR}" | sudo tee -a /etc/profile.d/opensearch.sh
echo "export OPENSEARCH_PATH_CONF=${INSTALL_DIR}/config" | sudo tee -a /etc/profile.d/opensearch.sh
echo "export JAVA_HOME=${JAVA_HOME_PATH}" | sudo tee -a /etc/profile.d/opensearch.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/opensearch.sh
chmod 755 /etc/profile.d/opensearch.sh
source /etc/profile.d/opensearch.sh
}

download_tar() {
    log_message "Checking for existing OpenSearch archive..."
    local tar_file="/opt/opensearch-${OPENSEARCH_VERSION}.tar.gz"

    # Check if the file already exists
    if [ ! -f "$tar_file" ]; then
        log_message "Downloading OpenSearch version ${OPENSEARCH_VERSION}..."
        wget -q "https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz" -O "$tar_file"
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to download OpenSearch tarball. Exiting."
            exit 1
        fi
    else
        log_message "OpenSearch archive already exists. Skipping download."
    fi

    # Extract the tarball
    log_message "Extracting OpenSearch archive..."
    tar -xzf "$tar_file" -C /opt
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to extract OpenSearch tarball. Exiting."
        exit 1
    fi

    # Move to installation directory
    log_message "Installing OpenSearch to ${INSTALL_DIR}..."
    if [ -d ${INSTALL_DIR} ]
    then
    log_message "Remove Old Installed Dir ${INSTALL_DIR}..."
    rm -rf ${INSTALL_DIR}
    sudo mv /opt/opensearch-${OPENSEARCH_VERSION} "${INSTALL_DIR}"
    else
    sudo mv /opt/opensearch-${OPENSEARCH_VERSION} "${INSTALL_DIR}"
    fi

    log_message "Creating OpenSearch user..."
    if ! id -u opensearch &>/dev/null; then
        sudo useradd opensearch
    fi
    # Set permissions
    log_message "Setting permissions for OpenSearch directory..."
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}"
    find "${INSTALL_DIR}" -iname "*.sh" -type f -exec chmod 755 {} \;
}


setup_admin_password() {
    log_message "Setting up admin password..."
    cat <<EOF | sudo tee "${INSTALL_DIR}/config/opensearch-security/internal_users.yml" > /dev/null
---
_meta:
  type: "internalusers"
  config_version: 2
admin:
  hash: "${ADMIN_PASSWORD_HASH}"
  reserved: true
  backend_roles:
  - "admin"
  description: "Admin user"
EOF
}

run_secure_admin_script() {
    log_message "Running security admin script..."
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}"
    cd "${INSTALL_DIR}/plugins/opensearch-security/tools/"
    ./securityadmin.sh -cd "${INSTALL_DIR}/config/opensearch-security/" \
        -cacert "${INSTALL_DIR}/config/root-ca.pem" \
        -cert "${INSTALL_DIR}/config/admin.pem" \
        -key "${INSTALL_DIR}/config/admin-key.pem" \
        -icl -nhnv
}

create_config_file() {
    log_message "Creating OpenSearch configuration..."
    cat <<EOF | sudo tee "${INSTALL_DIR}/config/opensearch.yml" > /dev/null
cluster.name: ${CLUSTER_NAME}
node.name: ${NODE_NAME}
network.host: ${NETWORK_HOST}
discovery.seed_hosts: ${SEED_HOSTS[*]}
cluster.initial_master_nodes: ${MASTER_NODES[*]}
bootstrap.memory_lock: true
plugins.security.ssl.transport.pemcert_filepath: ${INSTALL_DIR}/config/node1.pem
plugins.security.ssl.transport.pemkey_filepath: ${INSTALL_DIR}/config/node1-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: ${INSTALL_DIR}/config/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: ${INSTALL_DIR}/config/node1.pem
plugins.security.ssl.http.pemkey_filepath: ${INSTALL_DIR}/config/node1-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: ${INSTALL_DIR}/config/root-ca.pem
plugins.security.allow_default_init_securityindex: true
EOF
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}"
}

setup_openSSL() {
    log_message "Setting up OpenSSL certificates..."
    local CERT_DIR="${INSTALL_DIR}/config"
    cd "${CERT_DIR}"
    openssl genrsa -out root-ca-key.pem 2048
    openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "/C=CA/ST=ONTARIO/L=TORONTO/O=ORG/OU=UNIT/CN=root" -out root-ca.pem -days 730

    for node in node1 node2; do
        openssl genrsa -out ${node}-key-temp.pem 2048
        openssl pkcs8 -inform PEM -outform PEM -in ${node}-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ${node}-key.pem
        openssl req -new -key ${node}-key.pem -subj "/C=CA/ST=ONTARIO/L=TORONTO/O=ORG/OU=UNIT/CN=${node}" -out ${node}.csr
        echo "subjectAltName=DNS:${node}" > ${node}.ext
        openssl x509 -req -in ${node}.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out ${node}.pem -days 730 -extfile ${node}.ext
        rm -f ${node}-key-temp.pem ${node}.csr ${node}.ext
    done
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}"
}

start_opensearch() {
    log_message "Starting OpenSearch..."
    sudo chown -R opensearch:opensearch "${INSTALL_DIR}"
    sudo -u opensearch bash -c "${INSTALL_DIR}/bin/opensearch &"
    sleep 20
}

# Main
check_command wget
check_command openssl

download_tar
setup_environment
setup_openSSL
create_config_file
fix_permissions
# Hash password securely
ADMIN_PASSWORD_HASH=$("${INSTALL_DIR}/plugins/opensearch-security/tools/hash.sh" --password "${ADMIN_PASSWORD}")
setup_admin_password
start_opensearch
run_secure_admin_script
