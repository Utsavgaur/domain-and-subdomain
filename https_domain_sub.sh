#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -qw "$1"
}

# Update system packages
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Apache if not installed
if is_installed apache2; then
    echo "Apache is already installed. Skipping installation..."
else
    echo "Installing Apache..."
    sudo apt install apache2 -y
fi

# Enable necessary Apache modules for reverse proxy
echo "Enabling Apache modules..."
sudo a2enmod proxy proxy_http ssl rewrite headers
sudo systemctl restart apache2

# Install Odoo dependencies if not installed
if is_installed odoo; then
    echo "Odoo is already installed. Skipping installation..."
else
    echo "Installing Odoo dependencies..."
    sudo apt install python3-pip build-essential wget python3-dev python3-venv \
        python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev \
        python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev -y

    echo "Installing PostgreSQL..."
    if is_installed postgresql; then
        echo "PostgreSQL is already installed. Skipping..."
    else
        sudo apt install postgresql -y
    fi

    echo "Downloading and setting up Odoo..."
    sudo useradd -m -d /opt/odoo -U -r -s /bin/bash odoo
    sudo su - odoo -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch 16.0 /opt/odoo/odoo"
    sudo su - odoo -c "python3 -m venv /opt/odoo/venv"
    sudo su - odoo -c "/opt/odoo/venv/bin/pip install wheel"
    sudo su - odoo -c "/opt/odoo/venv/bin/pip install -r /opt/odoo/odoo/requirements.txt"

    # Create Odoo configuration file
    sudo tee /etc/odoo.conf > /dev/null <<EOL
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo/addons
EOL

    # Set permissions
    sudo chown odoo:odoo /etc/odoo.conf
    sudo chmod 640 /etc/odoo.conf

    # Create Odoo service
    sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOL
[Unit]
Description=Odoo
Documentation=https://www.odoo.com
[Service]
User=odoo
Group=odoo
ExecStart=/opt/odoo/venv/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf
[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd and enable Odoo service
    sudo systemctl daemon-reload
    sudo systemctl enable --now odoo
fi

# Get user inputs for dummy domain and subdomain
read -p "Enter main dummy domain (e.g., utsav.local): " DOMAIN
read -p "Enter subdomain (e.g., sub.utsav.local): " SUBDOMAIN

# Configure Apache reverse proxy for subdomain
echo "Configuring Apache for $SUBDOMAIN to serve Odoo..."
sudo tee /etc/apache2/sites-available/$SUBDOMAIN.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $SUBDOMAIN

    # Redirect HTTP to HTTPS
    Redirect permanent / https://$SUBDOMAIN/
</VirtualHost>

<VirtualHost *:443>
    ServerName $SUBDOMAIN

    # SSL configuration
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/$SUBDOMAIN.crt
    SSLCertificateKeyFile /etc/ssl/private/$SUBDOMAIN.key

    # Reverse proxy to Odoo
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8069/
    ProxyPassReverse / http://127.0.0.1:8069/

    # Security headers
    <IfModule mod_headers.c>
        Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
    </IfModule>
</VirtualHost>
EOL

# Generate self-signed SSL certificate for the subdomain
if [ ! -f /etc/ssl/certs/$SUBDOMAIN.crt ]; then
    echo "Generating self-signed SSL certificate for $SUBDOMAIN..."
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/$SUBDOMAIN.key -out /etc/ssl/certs/$SUBDOMAIN.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$SUBDOMAIN"
else
    echo "SSL certificate for $SUBDOMAIN already exists. Skipping..."
fi

# Update /etc/hosts file
if grep -q "$SUBDOMAIN" /etc/hosts; then
    echo "$SUBDOMAIN is already mapped in /etc/hosts. Skipping..."
else
    echo "Updating /etc/hosts file for $SUBDOMAIN..."
    sudo tee -a /etc/hosts > /dev/null <<EOL

# Dummy domains for local development
127.0.0.1 $SUBDOMAIN
EOL
fi

# Enable Apache site and restart services
echo "Enabling Apache site for $SUBDOMAIN and restarting services..."
sudo a2ensite $SUBDOMAIN.conf
sudo systemctl reload apache2

# Final message
echo "======================================"
echo "Setup complete!"
echo "Odoo is now accessible via the subdomain:"
echo "Subdomain (HTTPS): https://$SUBDOMAIN"
echo "======================================"

