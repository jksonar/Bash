#!/bin/bash
set -e  # Exit on error
set -o pipefail  # Catch errors in pipelines
set -u  # Treat unset variables as an error

TOMCAT_HOME="/opt/tomcat"
SERVICE_FILE=$(basename $TOMCAT_HOME)
JAVA_VER=""
JAVA_PACKAGE="17"
TOMCAT_FILE=""
TOMCAT_LINK=""
HOST_OS=""

# Detect OS
if command -v apt &>/dev/null; then
    HOST_OS="debian"
elif command -v yum &>/dev/null; then
    HOST_OS="centos"
else
    echo "Unsupported OS"
    exit 1
fi

install_java() {
    if command -v java &>/dev/null; then
        echo "Java is already installed."
        java -version
    else
        echo "Installing Java..."
        if [ "$HOST_OS" == "debian" ]; then
            apt update && apt install -y openjdk-${JAVA_PACKAGE}-jdk wget
        elif [ "$HOST_OS" == "centos" ]; then
            yum install -y java-${JAVA_PACKAGE}-openjdk java-${JAVA_PACKAGE}-openjdk-devel wget
        fi
    fi

    JAVA_VER=$(dirname $(dirname $(readlink -f $(which java))))
    echo "Java installed at $JAVA_VER"
}

install_tomcat() {
    if [ -d "$TOMCAT_HOME" ]; then
        echo "Tomcat directory already exists at $TOMCAT_HOME. Exiting."
        exit 1
    fi

    echo "Creating Tomcat user and directory..."
    useradd -r -m -d "$TOMCAT_HOME" -s /bin/false tomcat || true
    mkdir -p "$TOMCAT_HOME"

    if [ -n "$TOMCAT_FILE" ] && [ -f "$TOMCAT_FILE" ]; then
        echo "Extracting Tomcat from file..."
        tar xzvf "$TOMCAT_FILE" -C "$TOMCAT_HOME" --strip-components=1
    elif [ -n "$TOMCAT_LINK" ]; then
        echo "Downloading and extracting Tomcat..."
        wget "$TOMCAT_LINK" -O /tmp/tomcat.tar.gz
        tar xzvf /tmp/tomcat.tar.gz -C "$TOMCAT_HOME" --strip-components=1
    else
        echo "No Tomcat source specified. Exiting."
        exit 1
    fi

    chown -R tomcat:tomcat "$TOMCAT_HOME"
    chmod +x ${TOMCAT_HOME}/bin/*.sh
    SERVICE_FILE=$(basename $TOMCAT_HOME)
    cat > /etc/systemd/system/${SERVICE_FILE}.service << EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=$JAVA_VER"
Environment="CATALINA_HOME=$TOMCAT_HOME"
Environment="CATALINA_BASE=$TOMCAT_HOME"
ExecStart=$TOMCAT_HOME/bin/startup.sh
ExecStop=$TOMCAT_HOME/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${SERVICE_FILE}
    systemctl restart ${SERVICE_FILE}
    echo "Tomcat installed and started."
}

install_httpd() {
    echo "Installing HTTPD..."
    if [ "$HOST_OS" == "debian" ]; then
        apt install -y apache2 libapache2-mod-jk openssl
    elif [ "$HOST_OS" == "centos" ]; then
        yum install -y httpd mod_ssl
    fi
    systemctl enable httpd
    systemctl restart httpd
}

usage() {
    echo "Usage: $0 [-d <tomcat-dir>] [-j <java-number>] [-l <tomcat-link>] [-t <tomcat-file>]  [-a (install-httpd)]"
    exit 1
}

# Main
if [ $# -eq 0 ]; then
    usage
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -d) TOMCAT_HOME="$2"; shift 2 ;;
        -j) JAVA_PACKAGE="$2"; shift 2 ;;
        -l) TOMCAT_LINK="$2"; install_java; install_tomcat; shift 2 ;;
        -t) TOMCAT_FILE="$2"; install_java; install_tomcat; shift 2 ;;
        -a) install_httpd; shift 1 ;;
        *) usage ;;
    esac
done
