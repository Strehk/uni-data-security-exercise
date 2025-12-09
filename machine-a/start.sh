#!/bin/bash

echo "Starte Dienste..."

# Apache starten
service apache2 start

# Tomcat starten
service tomcat9 start

# FTP starten
service vsftpd start

# Postgres starten
service postgresql start

# MariaDB starten
service mariadb start

# User und DB Setup für MariaDB (damit Remote Zugriff geht)
mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'secret';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';"
mysql -e "FLUSH PRIVILEGES;"

echo "Alle Dienste gestartet. Halte Container offen..."

# Hack, um den Container am Laufen zu halten (tail auf ein Log)
tail -f /var/log/apache2/access.log
