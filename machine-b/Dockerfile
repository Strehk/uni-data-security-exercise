FROM ubuntu:24.04

# Wir setzen die Umgebungsvariable, weil apt-get sonst interaktive Eingaben verlangt
ENV DEBIAN_FRONTEND=noninteractive

# Installation der benötigten Pakete ohne empfohlene Zusatzpakete
RUN apt-get update && apt-get install -y --no-install-recommends \
  nmap \
  tshark \
  iptraf-ng \
  curl \
  wget \
  net-tools \
  iputils-ping \
  nano \
  ftp \
  && rm -rf /var/lib/apt/lists/*

# Wireshark Rechte setzen (verhindert Dialoge und Fehler)
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
RUN dpkg-reconfigure -f noninteractive wireshark-common

# Standardbefehl zum Offenhalten des Containers
CMD ["tail", "-f", "/dev/null"]
