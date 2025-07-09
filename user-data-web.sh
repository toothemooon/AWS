#!/bin/bash

# Update the system
yum update -y

# Install httpd and useful tools
yum install -y httpd htop tmux curl

# Start and enable httpd service
systemctl start httpd
systemctl enable httpd

# Create extremely simple index page with just server name
cat << 'HTMLEOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>${server_name}</title>
</head>
<body>
    <h1>${server_name}</h1>
</body>
</html>
HTMLEOF

# Create health check endpoint
cat << 'HEALTHEOF' > /var/www/html/health
{
  "status": "healthy",
  "server": "${server_name}"
}
HEALTHEOF

# Restart httpd
systemctl restart httpd

# Configure firewall
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Log completion
echo "Web server setup completed: ${server_name}" >> /var/log/user-data.log
