#!/bin/bash

echo "==== Iniciando Pós-instalação do TuxonOS ===="

# Atualizar o sistema
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Snapd se não estiver instalado
if ! command -v snap &> /dev/null; then
    echo "Instalando snapd..."
    sudo apt install snapd -y
    sudo systemctl enable --now snapd.socket
    sudo ln -s /var/lib/snapd/snap /snap
fi

# Instalar Visual Studio Code
echo "Instalando Visual Studio Code..."
sudo snap install code --classic

# Instalar Postman
echo "Instalando Postman..."
sudo snap install postman

Opcional: PhpStorm (Comente ou descomente se quiser)
echo "Instalando PhpStorm..."
wget https://download.jetbrains.com/webide/PhpStorm-2024.1.2.tar.gz -O /tmp/phpstorm.tar.gz
sudo mkdir -p /opt/phpstorm
sudo tar -xzf /tmp/phpstorm.tar.gz -C /opt/phpstorm --strip-components=1
sudo ln -s /opt/phpstorm/bin/phpstorm.sh /usr/local/bin/phpstorm
rm /tmp/phpstorm.tar.gz

echo "==== Pós-instalação do TuxonOS finalizada! ===="
