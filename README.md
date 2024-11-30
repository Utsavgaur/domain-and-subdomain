Odoo Setup with HTTPS Domain and Subdomain on Localhost

This repository provides scripts to set up Odoo on localhost with HTTPS, including domain and subdomain configuration using Apache and Docker. The scripts automate the installation and configuration process, ensuring Odoo is accessible over a secure HTTPS connection.
Features

    Automated HTTPS Configuration:
        Sets up a self-signed SSL certificate for HTTPS on localhost.
        Configures a domain and subdomain for Odoo.

    Dockerized Odoo Deployment:
        Deploys Odoo and PostgreSQL in Docker containers.

    Error Handling:
        Verifies if Odoo is running and accessible via HTTPS.
        Logs errors and attempts automatic fixes.

Prerequisites

    Operating System: Ubuntu 20.04 or later.
    OpenSSL installed for generating self-signed certificates.
    A user with sudo privileges.

Setup Instructions
Clone the Repository

git clone https://github.com/your-username/odoo-https-setup.git
cd odoo-https-setup

Step-by-Step Installation
1. Install Prerequisites

Run the script to install required tools and services:

sudo ./install_prerequisites.sh

2. Generate Self-Signed Certificates

Generate SSL certificates for HTTPS:

sudo ./generate_ssl.sh

    You will be prompted to enter details for the certificate.

3. Deploy Odoo with Docker

Run the script to deploy Odoo:

sudo ./install_odoo.sh

4. Configure HTTPS Domain/Subdomain

Run the script to configure HTTPS for a domain and subdomain:

sudo ./configure_apache_https.sh

    Enter the domain (e.g., example.com) and subdomain (e.g., odoo.example.com) when prompted.

5. Verify HTTPS Setup

Run the verification script to ensure everything is running correctly:

sudo ./verify_https_odoo.sh

Customization

    Domain and Subdomain: Modify the domain and subdomain inputs directly in configure_apache_https.sh.
    Odoo Ports: Update the port bindings in install_odoo.sh to match your local configuration.

Troubleshooting
Common Issues

    Certificate Not Recognized:
        Add the self-signed certificate to your system's trusted certificates:

    sudo cp /path/to/certificate.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates

Apache HTTPS Configuration Error: Check Apache's error log:

sudo tail -f /var/log/apache2/error.log

Odoo Not Running: Check the status of Docker containers:

    docker ps
    docker logs odoo

Security Notice

    Self-signed certificates are suitable for testing or local development but are not recommended for production environments.
    For production, use certificates from a trusted Certificate Authority (e.g., Let's Encrypt).

Contributing

Contributions are welcome! If you encounter issues or have suggestions, feel free to fork the repository and submit a pull request.
License

This project is licensed under the MIT License. See the LICENSE file for more details.
