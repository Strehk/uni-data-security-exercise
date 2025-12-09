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

# Wireshark (tshark) fragt normalerweise nach permissions, wir setzen das hier
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
RUN dpkg-reconfigure -f noninteractive wireshark-common

CMD ["tail", "-f", "/dev/null"]
