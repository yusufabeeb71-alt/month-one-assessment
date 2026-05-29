#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/user-data.log) 2>&1
echo "[$(date)] === Web server setup starting ==="


echo "[$(date)] Updating packages and installing Apache..."
yum update -y
yum install -y httpd

echo "[$(date)] Getting instance ID..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")

INSTANCE_ID=$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/instance-id")

echo "[$(date)] Instance ID: $INSTANCE_ID"



echo "[$(date)] Creating web page..."
cat > /var/www/html/index.html <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>TechCorp Web Server</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: Arial, sans-serif;
      background: #f0f4f8;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: white;
      padding: 48px 64px;
      border-radius: 12px;
      text-align: center;
      box-shadow: 0 4px 16px rgba(0,0,0,0.08);
    }
    h1 { color: #2d3748; margin-bottom: 8px; }
    .sub { color: #718096; margin-bottom: 32px; }
    .label { color: #4a5568; font-size: 13px; text-transform: uppercase;
             letter-spacing: 0.08em; margin-bottom: 8px; }
    .id { color: #3182ce; font-size: 20px; font-weight: bold;
          font-family: monospace; }
  </style>
</head>
<body>
  <div class="card">
    <h1>TechCorp Application</h1>
    <p class="sub">Web Server &mdash; Online</p>
    <p class="label">Serving from instance</p>
    <p class="id">$INSTANCE_ID</p>
  </div>
</body>
</html>
HTMLEOF 

echo "[$(date)] Creating webuser account..."
id -u webuser &>/dev/null || useradd -m webuser

echo "[$(date)] Enabling password SSH authentication..."
sed -i '/^#*PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
systemctl restart sshd


echo "[$(date)] Starting Apache..."
systemctl start httpd
systemctl enable httpd # start automatically on every future reboot

echo "[$(date)] === Web server setup complete ==="