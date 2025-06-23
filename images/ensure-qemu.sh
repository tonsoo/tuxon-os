#!/bin/bash

if ! command -v qemu-system-x86_64 &> /dev/null
then
    echo "To run this OS it's necessary to have qemu-system-x86_64 installed."
    read -p "Do you wish to install it? (yes/no): " choice
    case "$choice" in
        yes|Yes|Y|y )
            sudo apt install -y qemu-system-x86
            ;;
        * )
            echo "QEMU not installed. Exiting."
            exit 1
            ;;
    esac
fi