#!/bin/bash

# Update the system
yum update -y

# Install httpd and useful tools
yum install -y httpd htop tmux curl

# Start and enable httpd service
systemctl start httpd
systemctl enable httpd

# Create main index page with simple server-specific content
cat << 'HTMLEOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>${server_name}</title>
</head>
<body>
    <h1>${server_name}</h1>
    <h2>Server Status: ONLINE</h2>
    
    <h3>Server Information:</h3>
    <ul>
        <li>Server Name: ${server_name}</li>
        <li>Availability Zone: ${az_name}</li>
        <li>Date: $(date)</li>
    </ul>
    
    <h3>Load Balancer Test:</h3>
    <p>Refresh this page multiple times to see different servers!</p>
    
    <hr>
    <p><strong>This is ${server_name} serving your request.</strong></p>
    
    <h3>Available Pages:</h3>
    <ul>
        <li><a href="/">Home Page</a></li>
        <li><a href="/health">Health Check</a></li>
        <li><a href="/status.html">Status Page</a></li>
    </ul>
</body>
</html>
HTMLEOF

# Create health check endpoint
cat << 'HEALTHEOF' > /var/www/html/health
{
  "status": "healthy",
  "server": "${server_name}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "httpd_status": "running"
}
HEALTHEOF

# Create a simple status page
echo "<html><body><h1>${server_name} - Status OK</h1><p>Server is running in ${az_name}</p><p>Current time: $(date)</p><p><a href='/'>Back to Home</a></p></body></html>" > /var/www/html/status.html

# Restart httpd to apply configuration changes
systemctl restart httpd

# Configure firewall (if needed)
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Log completion
echo "Web server setup completed at $(date)" >> /var/log/user-data.log
echo "Server: ${server_name}" >> /var/log/user-data.log
echo "AZ: ${az_name}" >> /var/log/user-data.log
