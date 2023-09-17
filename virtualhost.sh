#!/bin/bash

# Function to create a new virtual host
create_virtual_host() {
    # Get user input for domain name and document root
    read -p "Enter the domain name (e.g., example.com): " domain_name
    read -p "Enter the document root path (e.g., /var/www/html/example): " document_root

    # Check if the directory already exists
    if [ -d "$document_root" ]; then
        echo "Error: Directory '$document_root' already exists. Exiting..."
        exit 1
    fi

    # Create the document root directory
    sudo mkdir -p "$document_root"

    # Set appropriate permissions for the document root directory
    sudo chown -R www-data:www-data "$document_root"
    sudo chmod -R 755 "$document_root"

    # Create a default index.html if it doesn't exist
    index_file="$document_root/index.html"
    if [ ! -f "$index_file" ]; then
        echo "<html><head><title>Welcome to ${domain_name}</title></head><body><h1>It works!</h1></body></html>" | sudo tee "$index_file" > /dev/null
        sudo chown www-data:www-data "$index_file"
        sudo chmod 644 "$index_file"
    fi

    # Create a new virtual host configuration file
    sudo tee "/etc/apache2/sites-available/${domain_name}.conf" > /dev/null <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@${domain_name}
    ServerName ${domain_name}
    DocumentRoot ${document_root}

    ErrorLog \${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain_name}_access.log combined

    <Directory ${document_root}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

    # Enable the virtual host
    sudo a2ensite "${domain_name}"

    # Reload Apache2 for changes to take effect
    sudo systemctl reload apache2

    # Update the hosts file to map the domain name to localhost
    echo "127.0.0.1 ${domain_name}" | sudo tee -a /etc/hosts

    echo "Virtual host '${domain_name}' has been set up successfully!"
}

# Check if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (sudo). Exiting..."
    exit 1
fi

# Run the script
create_virtual_host
	