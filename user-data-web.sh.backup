#!/bin/bash

# Update the system
yum update -y

# Install httpd and useful tools
yum install -y httpd htop tmux curl

# Start and enable httpd service
systemctl start httpd
systemctl enable httpd

# Create main index page with server-specific content
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${server_name}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .info {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .server-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 30px;
        }
        .metric {
            background: rgba(255, 255, 255, 0.1);
            padding: 15px;
            border-radius: 5px;
        }
        .status {
            color: #4CAF50;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 ${server_name}</h1>
        <div class="info">
            <h2>Server Status: <span class="status">ONLINE</span></h2>
            <p>This server is running Apache httpd and is ready to serve requests!</p>
        </div>
        
        <div class="server-info">
            <div class="metric">
                <h3>Server Name</h3>
                <p>${server_name}</p>
            </div>
            <div class="metric">
                <h3>Availability Zone</h3>
                <p>${az_name}</p>
            </div>
            <div class="metric">
                <h3>Instance ID</h3>
                <p id="instance-id">Loading...</p>
            </div>
            <div class="metric">
                <h3>Local IP</h3>
                <p id="local-ip">Loading...</p>
            </div>
        </div>
        
        <div class="info">
            <h3>Load Balancer Test</h3>
            <p>Refresh this page multiple times to see load balancing in action!</p>
            <p>Each server has unique content to demonstrate traffic distribution.</p>
        </div>
    </div>

    <script>
        // Fetch instance metadata
        fetch('/instance-info')
            .then(response => response.json())
            .then(data => {
                document.getElementById('instance-id').textContent = data.instance_id || 'N/A';
                document.getElementById('local-ip').textContent = data.local_ip || 'N/A';
            })
            .catch(error => {
                document.getElementById('instance-id').textContent = 'Error loading';
                document.getElementById('local-ip').textContent = 'Error loading';
            });
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat << 'EOF' > /var/www/html/health
{
  "status": "healthy",
  "server": "${server_name}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "uptime": "$(uptime)",
  "httpd_status": "running"
}
EOF

# Create instance info endpoint for dynamic content
cat << 'EOF' > /var/www/html/instance-info
#!/bin/bash
echo "Content-Type: application/json"
echo ""
echo "{"
echo "  \"instance_id\": \"$(curl -s http://169.254.169.254/latest/meta-data/instance-id)\","
echo "  \"local_ip\": \"$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)\","
echo "  \"az\": \"$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)\","
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
echo "}"
EOF

# Make the instance-info script executable
chmod +x /var/www/html/instance-info

# Configure httpd to execute CGI scripts
cat << 'EOF' >> /etc/httpd/conf/httpd.conf

# Enable CGI for instance-info endpoint
ScriptAlias /instance-info /var/www/html/instance-info
<Directory "/var/www/html">
    Options +ExecCGI
    AddHandler cgi-script .cgi
</Directory>
EOF

# Create a simple status page
echo "<h1>${server_name} - Status OK</h1><p>Server is running in ${az_name}</p><p>$(date)</p>" > /var/www/html/status.html

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