#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/user-data.log) 2>&1
echo "[$(date)] === Database server setup starting ==="

echo "[$(date)] Updating packages..."
yum update -y

echo "[$(date)] Installing PostgreSQL 14..."
amazon-linux-extras enable postgresql14
yum install -y postgresql-server

echo "[$(date)] Initialising PostgreSQL..."
postgresql-setup initdb

echo "[$(date)] Configuring PostgreSQL to accept remote connections..."


sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
  /var/lib/pgsql/data/postgresql.conf

sed -i \
  "s|host    all             all             127.0.0.1/32            ident|host    all             all             127.0.0.1/32            md5|" \
  /var/lib/pgsql/data/pg_hba.conf

sed -i \
  "s|local   all             all                                     peer|local   all             all                                     md5|" \
  /var/lib/pgsql/data/pg_hba.conf

echo "host    all             all             10.0.0.0/16             md5" \
  >> /var/lib/pgsql/data/pg_hba.conf

echo "[$(date)] Starting PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

sleep 3

echo "[$(date)] Creating database and user..."
sudo -u postgres psql <<SQLEOF
CREATE USER techcorp WITH PASSWORD '${db_password}';
CREATE DATABASE techcorp_db OWNER techcorp;
GRANT ALL PRIVILEGES ON DATABASE techcorp_db TO techcorp;
SQLEOF

echo "[$(date)] Database and user created."


echo "[$(date)] Creating dbuser account..."
id -u dbuser &>/dev/null || useradd -m dbuser
echo "dbuser:${db_password}" | chpasswd

echo "[$(date)] Enabling password SSH authentication..."
sed -i '/^#*PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
systemctl restart sshd


echo "[$(date)] === Database server setup complete ==="