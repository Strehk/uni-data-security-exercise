#!/bin/bash
set -e

# Start necessary services and configure DBs for first run

# Helper to run commands in background and wait
run_bg() {
  "$@" &
}

# Configure MariaDB for remote access and set root password on first run
if [ ! -f /var/lib/mysql/.initialized ]; then
  echo "Initializing MariaDB..."
  service mysql start
  sleep 3
  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" || true
  mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;" || true
  touch /var/lib/mysql/.initialized
  service mysql stop
fi

# Configure PostgreSQL for remote access and set postgres password on first run
if [ ! -f /var/lib/postgresql/.initialized ]; then
  echo "Initializing PostgreSQL..."
  service postgresql start
  sleep 3
  # allow remote connections
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/'" /etc/postgresql/*/main/postgresql.conf || true
  echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/*/main/pg_hba.conf || true
  sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';" || true
  touch /var/lib/postgresql/.initialized
  service postgresql stop
fi

# Ensure Apache index exists
if [ ! -f /var/www/html/index.php ]; then
  echo "<?php phpinfo(); ?>" > /var/www/html/index.php
fi

# Start services in foreground where possible
service mysql start
service postgresql start
if [ -d /opt/tomcat/bin ]; then
  echo "Starting Tomcat from /opt/tomcat..."
  /opt/tomcat/bin/startup.sh || true
else
  #!/bin/bash
  set -e

  echo "[start-services] starting..."

  # Helper: try command ignoring errors
  try() {
    "$@" || true
  }

  # Configure MariaDB for remote access and set root password on first run
  if [ ! -f /var/lib/mysql/.initialized ]; then
    echo "[start-services] Initializing MariaDB..."
    # try common service names
    try service mariadb start
    try service mysql start
    try service mysqld start
    sleep 3
    # Set root password and allow remote access (best-effort)
    try mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';"
    try mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"
    touch /var/lib/mysql/.initialized
    try service mariadb stop
    try service mysql stop
    try service mysqld stop
  fi

  # Configure PostgreSQL for remote access and set postgres password on first run
  if [ ! -f /var/lib/postgresql/.initialized ]; then
    echo "[start-services] Initializing PostgreSQL..."
    try service postgresql start
    sleep 3
    # allow remote connections where config files exist
    for cfg in /etc/postgresql/*/main/postgresql.conf; do
      if [ -f "$cfg" ]; then
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/'" "$cfg" || true
      fi
    done
    for hba in /etc/postgresql/*/main/pg_hba.conf; do
      if [ -f "$hba" ]; then
        echo "host    all             all             0.0.0.0/0               md5" >> "$hba" || true
      fi
    done
    try sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
    touch /var/lib/postgresql/.initialized
    try service postgresql stop
  fi

  # Ensure Apache index exists
  if [ ! -f /var/www/html/index.php ]; then
    echo "<?php phpinfo(); ?>" > /var/www/html/index.php
  fi

  echo "[start-services] Starting services..."

  # Start DBs
  try service mariadb start || true
  try service mysql start || true
  try service mysqld start || true
  try service postgresql start || true

  # Start Tomcat (manual install in /opt/tomcat or package)
  if [ -d /opt/tomcat/bin ]; then
    echo "[start-services] Starting Tomcat from /opt/tomcat"
    try /opt/tomcat/bin/startup.sh
  else
    try service tomcat9 start
  fi

  # Start Apache and FTP
  try service apache2 start
  try service vsftpd start

  echo "[start-services] All services started. Tailing logs."

  # Keep container running
  tail -f /dev/null
