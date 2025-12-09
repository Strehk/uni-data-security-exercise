FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --fix-missing && apt-get install -y \
  nmap \
  tshark \
  iptraf-ng \
  curl \
  wget \
  net-tools \
  iputils-ping \
  nano \
  ftp \
  inetutils-telnet \
  && rm -rf /var/lib/apt/lists/*

# Konfigurationen anpassen (Quick & Dirty für Lab-Zwecke)

# Apache: index.php aktivieren (wird später reinkopiert)
RUN rm /var/www/html/index.html

# FTP: User anlegen (user: "student", pass: "secret")
RUN useradd -m student && echo "student:secret" | chpasswd
# vsftpd conf anpassen für lokalen Zugriff
RUN echo "write_enable=YES" >> /etc/vsftpd.conf

# PostgreSQL Config für Remote Access (Vorsicht: Unsicher, nur für Labor!)
RUN echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
RUN echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/14/main/pg_hba.conf

# MariaDB Config für Remote Access
RUN sed -i 's/bind-address            = 127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Datei für Startskript kopieren
COPY start.sh /start.sh
COPY index.php /var/www/html/index.php
RUN chmod +x /start.sh

# Ports exponieren (intern im Docker Netzwerk)
EXPOSE 80 21 3306 5432 8080

CMD ["/start.sh"]
