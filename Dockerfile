FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

RUN apt update && apt install -y \
    debootstrap ubuntu-keyring gnupg2 apt-transport-https ca-certificates \
    build-essential bc bison flex libssl-dev libncurses5-dev wget git \
    squashfs-tools xorriso grub-pc-bin cpio initramfs-tools libelf-dev tar gzip xz-utils \
    curl file rsync util-linux

RUN mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/ubuntu-archive-keyring.gpg https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x437D05B5C176C64D && \
    wget -O /etc/apt/keyrings/ubuntu-security-archive-keyring.gpg https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF6ECB3762474EDA9

WORKDIR /build

RUN mkdir -p /build && chmod 777 /build

COPY . .
RUN chmod +x scripts/*.sh kernel/*.sh