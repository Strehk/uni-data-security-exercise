FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

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

# Apache Konfiguration:
# Wir nutzen rm -f (force), damit der Build nicht abbricht, falls die Datei fehlt
RUN rm -f /var/www/html/index.html
RUN rm -f /var/www/html/index.php

# FTP Setup
RUN useradd -m student && echo "student:secret" | chpasswd
RUN echo "write_enable=YES" >> /etc/vsftpd.conf

# DB Konfigurationen für Remote-Zugriff (Lab-Settings!)
RUN echo "listen_addresses = '*'" >> /etc/postgresql/16/main/postgresql.conf || echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf
RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/16/main/pg_hba.conf || echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/*/main/pg_hba.conf
RUN sed -i 's/bind-address            = 127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY start.sh /start.sh
COPY index.php /var/www/html/index.php
RUN chmod +x /start.sh

EXPOSE 80 21 3306 5432 8080

CMD ["/start.sh"]
