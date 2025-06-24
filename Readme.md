# TuxonOS - Distribuição Ubuntu Customizada para Tuxon Soluções Web

## 🚀 Visão Geral

TuxonOS é um sistema operacional customizado construído sobre a base do Ubuntu 24.04 LTS (Noble), especificamente adaptado para a **Tuxon Soluções Web**. Este projeto oferece um método reprodutível para gerar uma imagem ISO instalável e "live", completa com branding personalizado e um conjunto predefinido de pacotes de software essenciais.

O objetivo do TuxonOS é proporcionar um ambiente de computação padronizado e otimizado para as operações da empresa, garantindo consistência em todas as implantações e uma experiência de usuário simplificada.

## ✨ Funcionalidades

* **Baseado no Ubuntu 24.04 LTS (Noble):** Aproveitando a estabilidade e o vasto ecossistema de pacotes da mais recente versão de suporte de longo prazo do Ubuntu;
* **Branding Personalizado:** Substitui elementos padrão de branding do Ubuntu por logotipos, wallpapers e strings de texto específicos do "TuxonOS" em todo o sistema;
* **Software Pré-instalado:** Inclui uma seleção de aplicativos e ferramentas essenciais para desenvolvimento e uso diário, definidos no arquivo `packages.txt`;
* **ISO Bootável (Live):** Gera uma imagem ISO bootável que pode ser usada para experimentar o TuxonOS sem instalação ou para instalá-lo em hardware.
* **Suporte a Boot Híbrido:** A ISO gerada suporta métodos de boot tanto BIOS tradicional quanto UEFI moderno.
* **Processo de Build Contenizado:** Todo o processo de construção do sistema operacional é encapsulado dentro de um container Docker, garantindo builds consistentes e repetíveis em diferentes ambientes.

## 🛠️ Processo de Construção

A ISO do TuxonOS é gerada utilizando um processo de build Docker multiestágio, que encapsula todas as ferramentas e etapas necessárias.

### Pré-requisitos

* [**Docker**](https://docs.docker.com/get-docker/) instalado e em execução no seu sistema.

### Passos para Construir a ISO

1.  **Clone o Repositório (ou garanta que todos os arquivos estejam em um único diretório):**
    Certifique-se de ter o `Dockerfile`, `packages.txt`, o diretório `branding/` (contendo `logo.png` e `wallpaper.png`) e o diretório `scripts/` no seu diretório de trabalho.

2.  **Construa a Imagem Docker:**
    Este comando inicia o processo de build do Docker. Ele fará o download da imagem base do Ubuntu, configurará o ambiente chroot, instalará os pacotes, aplicará o branding e, por fim, gerará o arquivo ISO.

    ```bash
    docker build -t tuxon-os/builder .
    ```
    * `-t tuxon-os/builder`: Tag (etiqueta) a imagem Docker resultante como `tuxon-os/builder`. Você pode escolher qualquer nome.
    * `.`: Especifica que o `Dockerfile` está no diretório atual.

3.  **Extraia a ISO Gerada:**
    Após a conclusão do build, o arquivo ISO estará localizado *dentro* da imagem Docker. Este comando executa um container temporário a partir da sua imagem construída e copia a ISO para um diretório local chamado `output`.

    ```bash
    docker run --rm -v "$(pwd)/output:/output" tuxon-os/builder
    ```
    * `--rm`: Remove automaticamente o container após sua saída.
    * `-v "$(pwd)/output:/output"`: Monta seu diretório local `output` (criado no seu diretório de trabalho atual) para o diretório `/output` dentro do container. É para cá que a ISO é copiada.
    * `tuxon-os/builder`: Refere-se à imagem Docker que você acabou de construir.

Após a execução desses comandos, você encontrará `TuxonOS.iso` no diretório `output/` na sua pasta de projeto local.

## 📦 Customização

### Pré-instalação de Pacotes

A lista de pacotes de software adicionais a serem instalados no TuxonOS é definida no arquivo [**packages.txt**](packages.txt). Cada nome de pacote deve estar em uma nova linha.

**Exemplo de conteúdo de `packages.txt`:**
```
git
vim
htop
firefox
xubuntu-desktop
```

Basta modificar este arquivo antes de executar o comando `docker build` para incluir ou remover os pacotes desejados.

---

### Alteração do Branding

Todos os ativos de branding personalizados (logotipos, wallpapers) estão localizados no diretório [**branding/**](branding).

* `branding/logo.png`: Usado para o splash de boot do Plymouth.
* `branding/wallpaper.png`: Usado como papel de parede padrão da área de trabalho.

Você pode substituir esses arquivos pelas suas próprias imagens, garantindo que mantenham os mesmos nomes de arquivo.

Adicionalmente, o `Dockerfile` contém comandos `sed` que substituem várias ocorrências da string "Ubuntu" por "TuxonOS" em arquivos de configuração do sistema, incluindo:
* `/etc/os-release`
* `/etc/issue` e `/etc/issue.net`
* Scripts em `/etc/update-motd.d/`
* `/etc/hostname`
* `/etc/casper.conf` (para nomes de usuário e sistema "live")
* `/etc/lsb-release`


Algoritmo para Pós-Instalação do TuxonOS

Passos:
1. Abrir terminal
   - Inicie o terminal no sistema.

2. Navegar até a pasta do script
   - Use o comando: cd /home/seu-usuario/
   - Substitua "seu-usario" pelo nome do seu usuário.

3. Configurar permissões do script
   - Execute: chmod +x post-install.sh

4. Executar o script com superusuário
   - Execute: sudo ./post-install.sh

Observação:
- O script requer permissões de superusuário, então o uso de sudo é necessário.