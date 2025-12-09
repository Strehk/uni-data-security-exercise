FROM kalilinux/kali-rolling

RUN apt update && \
    apt upgrade -y && \
    apt-get update && \
    apt-get upgrade -y

RUN apt install kali-linux-headless -y

ENTRYPOINT [ "tail", "-f", "/dev/null" ]