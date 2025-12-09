FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends 

# Disable firewall (no iptables/firewalld installed)

COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

EXPOSE 80 8080 21 3306 5432

ENTRYPOINT ["/usr/local/bin/start-services.sh"]