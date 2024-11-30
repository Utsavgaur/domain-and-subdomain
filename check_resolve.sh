#!/bin/bash

# Function to check if running as root
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "This script requires root permissions. Attempting to run as root..."
        sudo "$0" "$@"
        exit
    fi
}

# Function to check if Odoo directory exists
check_odoo_directory() {
    if [ ! -d "/opt/odoo/odoo" ]; then
        echo "Odoo directory not found. Attempting to install Odoo..."
        install_odoo
    else
        echo "Odoo directory exists."
    fi
}

# Function to install Odoo if not found
install_odoo() {
    echo "Creating /opt/odoo directory and downloading Odoo..."
    
    sudo mkdir -p /opt/odoo
    cd /opt/odoo || exit

    # Download the latest Odoo
    sudo wget https://github.com/odoo/odoo/archive/refs/tags/15.0.tar.gz -O /opt/odoo/odoo.tar.gz
    sudo tar -xvzf /opt/odoo/odoo.tar.gz --strip-components=1
    sudo rm /opt/odoo/odoo.tar.gz

    echo "Odoo downloaded successfully."

    # Install dependencies
    sudo apt update
    sudo apt install -y python3-pip python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libmysqlclient-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev

    # Set up a Python virtual environment
    sudo python3 -m venv /opt/odoo/venv
    source /opt/odoo/venv/bin/activate
    sudo pip install -r /opt/odoo/requirements.txt

    echo "Odoo installed successfully."
}

# Function to check if Odoo service is running
check_odoo_service() {
    service_status=$(sudo systemctl is-active odoo)
    if [ "$service_status" != "active" ]; then
        echo "Odoo service is not running. Attempting to start Odoo service..."
        sudo systemctl start odoo
        if [ "$?" -eq 0 ]; then
            echo "Odoo service started successfully."
        else
            echo "Failed to start Odoo service. Checking logs..."
            sudo journalctl -u odoo -f
        fi
    else
        echo "Odoo service is running."
    fi
}

# Function to check Apache logs for issues
check_apache_logs() {
    echo "Checking Apache logs for errors..."
    apache_logs=$(sudo tail -n 20 /var/log/apache2/error.log)
    echo "$apache_logs"

    if [[ "$apache_logs" =~ "connection refused" ]]; then
        echo "Apache encountered issues connecting to Odoo. Attempting to fix Apache configuration..."
        fix_apache_config
    fi
}

# Function to fix Apache config (e.g., proxy settings)
fix_apache_config() {
    echo "Fixing Apache configuration to properly proxy to Odoo..."

    # Check if the proxy module is enabled
    sudo a2enmod proxy
    sudo a2enmod proxy_http

    # Modify the Apache virtual host to ensure it's correctly proxying requests to Odoo
    sudo sed -i '/<VirtualHost \*:443>/,/<\/VirtualHost>/s|#ProxyPass|ProxyPass|' /etc/apache2/sites-available/000-default.conf
    sudo sed -i '/<VirtualHost \*:443>/,/<\/VirtualHost>/s|#ProxyPassReverse|ProxyPassReverse|' /etc/apache2/sites-available/000-default.conf
    sudo systemctl restart apache2

    echo "Apache configuration updated and service restarted."
}

# Function to check SSL certificate issues
check_ssl_certificate() {
    echo "Checking SSL certificate for the domain..."
    apache_ssl_logs=$(sudo tail -n 20 /var/log/apache2/ssl_error.log)
    echo "$apache_ssl_logs"

    if [[ "$apache_ssl_logs" =~ "certificate is a CA certificate" ]]; then
        echo "SSL certificate is not valid. Please install a valid SSL certificate."
    fi
}

# Main script
check_root
check_odoo_directory
check_odoo_service
check_apache_logs
check_ssl_certificate

echo "Script completed. Please verify if the issue is resolved."

