FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Pakete installieren
RUN apt-get update && apt-get install -y \
  apache2 \
  php \
  libapache2-mod-php \
  mariadb-server \
  postgresql \
  vsftpd \
  tomcat10 \
  snort \
  net-tools \
  iputils-ping \
  nano \
  curl \
  iptables \
  sudo \
  && rm -rf /var/lib/apt/lists/*

# Apache Konfiguration
RUN rm -f /var/www/html/index.html
RUN rm -f /var/www/html/index.php

# PHP Index Seite erstellen
RUN echo '<?php echo "<h1>Willkommen auf Machine A (10.10.10.10)</h1><p>Dies ist eine unsichere Seite.</p>"; ?>' > /var/www/html/index.php

# FTP Setup
RUN useradd -m student && echo "student:secret" | chpasswd
RUN echo "write_enable=YES" >> /etc/vsftpd.conf

# Datenbank Setup (Remote Access erlauben)
RUN echo "listen_addresses = '*'" >> /etc/postgresql/16/main/postgresql.conf || echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/16/main/pg_hba.conf || echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/*/main/pg_hba.conf
RUN sed -i 's/bind-address            = 127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# --- START SCRIPT GENERIERUNG (Windows-sicher) ---
# Wir schreiben den Inhalt direkt in die Datei /start.sh
RUN echo '#!/bin/bash\n\
  \n\
  echo "Starte Dienste..."\n\
  \n\
  service apache2 start\n\
  service tomcat10 start || service tomcat9 start\n\
  service vsftpd start\n\
  service postgresql start\n\
  service mariadb start\n\
  \n\
  # DB User Setup\n\
  mysql -e "CREATE USER IF NOT EXISTS '"'admin'"'@'"'%'"' IDENTIFIED BY '"'secret'"';"\n\
  mysql -e "GRANT ALL PRIVILEGES ON *.* TO '"'admin'"'@'"'%'"';"\n\
  mysql -e "FLUSH PRIVILEGES;"\n\
  \n\
  echo "Alle Dienste gestartet. Halte Container offen..."\n\
  \n\
  # Container am Leben halten\n\
  tail -f /var/log/apache2/access.log\n\
  ' > /start.sh

# Ausführbar machen
RUN chmod +x /start.sh

EXPOSE 80 21 3306 5432 8080

CMD ["/start.sh"]
