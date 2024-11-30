#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

echo "Starting automated issue resolution..."

# Fix Elasticsearch http.port duplication
ES_CONFIG="/etc/elasticsearch/elasticsearch.yml"
if grep -q "http.port" "$ES_CONFIG"; then
    echo "Fixing duplicate http.port in Elasticsearch configuration..."
    sed -i '/http.port/!b;n;/http.port/d' "$ES_CONFIG"
    echo "Duplicate http.port entries removed."
fi

# Restart Elasticsearch service
echo "Restarting Elasticsearch service..."
systemctl restart elasticsearch
if systemctl is-active --quiet elasticsearch; then
    echo "Elasticsearch restarted successfully."
else
    echo "Failed to restart Elasticsearch. Check logs for details."
    exit 1
fi

# Fix APT dependency issues
echo "Fixing APT dependencies..."
apt update
apt --fix-broken install -y
apt install -y libldap-dev=2.5.16+dfsg-0ubuntu0.22.04.2 libsasl2-dev=2.1.27+dfsg2-3ubuntu1 python3-venv=3.10.6-1~22.04
if [ $? -eq 0 ]; then
    echo "APT dependencies resolved successfully."
else
    echo "Failed to resolve APT dependencies. Check logs for details."
    exit 1
fi

# Ensure python3.10-venv is installed
echo "Installing python3.10-venv..."
apt install -y python3.10-venv
if [ $? -eq 0 ]; then
    echo "python3.10-venv installed successfully."
else
    echo "Failed to install python3.10-venv. Check logs for details."
    exit 1
fi

# Recreate Odoo virtual environment
ODOO_DIR="/opt/odoo"
echo "Setting up Odoo virtual environment..."
if [ -d "$ODOO_DIR/venv" ]; then
    rm -rf "$ODOO_DIR/venv"
fi
python3 -m venv "$ODOO_DIR/venv"
source "$ODOO_DIR/venv/bin/activate"
pip install -r "$ODOO_DIR/odoo/requirements.txt"
deactivate

# Restart Odoo service
echo "Restarting Odoo service..."
systemctl restart odoo
if systemctl is-active --quiet odoo; then
    echo "Odoo service restarted successfully."
else
    echo "Failed to restart Odoo service. Check logs for details."
    exit 1
fi

# Restart Apache service
echo "Restarting Apache service..."
systemctl restart apache2
if systemctl is-active --quiet apache2; then
    echo "Apache restarted successfully."
else
    echo "Failed to restart Apache. Check logs for details."
    exit 1
fi

# Final status check
echo "Checking service statuses..."
systemctl status elasticsearch
systemctl status odoo
systemctl status apache2

echo "All issues resolved. You can now access Odoo at https://utsav.jkmall"

