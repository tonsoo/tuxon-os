#!/bin/bash

# App settings
APP_NAME="VPN Manager"
VERSION="0.0.1"
CMD="vpn"
DEBUG=0
HELP=0

# Variáveis de configuração
INPUT_ISO=""
OUTPUT_DIR="output_iso"
TEMP_MOUNT_POINT="temp_iso_mount" # Será ./temp_iso_mount
LIVE_FS_DIR="edit_chroot"       # Será ./edit_chroot
ISO_BUILD_DIR="iso_stage"       # Será ./iso_stage
ISO_LABEL="TuxonOS"      # Nome da sua distro na ISO

# Flags de ação
ACTION_CHROOT_MANUAL=0
ACTION_BUILD_ISO=0

# Functions
script() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # O $1 já virá como "definitions/functions.sh" ou "ui/open.sh"
    echo "$SCRIPT_DIR/$1" # Adicione aspas duplas aqui para o caso de $SCRIPT_DIR ter espaços
}

import() {
    local SCRIPT="$(script "$1")" # Garanta as aspas aqui também ao chamar 'script'

    if [ ! -f "$SCRIPT" ]; then # Aspas duplas aqui
        echo "Failed to import $2: File $SCRIPT could not be found."
        debug "err: File $SCRIPT could not be found"
        exit 1
    fi

    source "$SCRIPT" # Aspas duplas aqui
}

# Handle arguments
handleArgs() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d) DEBUG=1;;
            -h) HELP=1;;
            -i)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    INPUT_ISO="$2"
                    shift
                else
                    echo "Error: -i requires an ISO path."
                    exit 1
                fi
                ;;
            -o)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    OUTPUT_DIR="$2"
                    shift
                else
                    echo "Error: -o requires an output directory."
                    exit 1
                fi
                ;;
            --chroot) ACTION_CHROOT_MANUAL=1;;
            --build) ACTION_BUILD_ISO=1;;
            *) echo "Unknown argument passed: $1"; exit 1 ;;
        esac
        shift
    done
}

# Only echo arg 1 if in debug mode
debug() {
    if [ $DEBUG = 1 ]; then
        echo "DEBUG: $1"
    fi
}

# Messages
WELCOME_MSG="Opening $APP_NAME ($VERSION)"
UI_ERROR_NOT_FOUND="UI file not found"
ERROR_NO_ACTION="No action specified. Use --build or --chroot or -h for help."


handleArgs "$@"


debug "Step 1: Loading program functions"
import "definitions/functions.sh" "function" # <- Caminho relativo à pasta do vpn.sh

if [ $HELP == 1 ]; then
    help
    exit 0
fi

echo "$WELCOME_MSG"

debug "Step 2: Attempting to open UI lib..."
import "ui/open.sh" "ui" # <- Caminho relativo à pasta do vpn.sh

# Verificar dependências
log_step "Checking required commands..."
check_command "sudo"
check_command "mount"
check_command "umount"
check_command "unsquashfs"
check_command "mksquashfs"
check_command "xorriso"

# Verificar se uma ISO de entrada foi fornecida para ações de construção
if [[ "$ACTION_BUILD_ISO" == 1 || "$ACTION_CHROOT_MANUAL" == 1 ]]; then
    if [ -z "$INPUT_ISO" ]; then
        echo "Error: An input ISO must be specified with -i <path> for build or chroot actions."
        exit 1
    fi
    if [ ! -f "$INPUT_ISO" ]; then
        echo "Error: $ERROR_ISO_NOT_FOUND: $INPUT_ISO"
        exit 1
    fi
fi

# Criar diretórios de trabalho
log_step "Creating working directories..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_MOUNT_POINT"
mkdir -p "$LIVE_FS_DIR"
mkdir -p "$ISO_BUILD_DIR"

# Ações principais
if [ "$ACTION_BUILD_ISO" == 1 ]; then
    log_step "Starting full ISO build process..."

    # 2. Montar a ISO Base
    # Construa o caminho absoluto para o ponto de montagem antes de passar
    FULL_TEMP_MOUNT_PATH="$(pwd)/$TEMP_MOUNT_POINT"
    log_step "Mounting ISO: $INPUT_ISO to $FULL_TEMP_MOUNT_PATH"
    mount_iso "$INPUT_ISO" "$FULL_TEMP_MOUNT_PATH"

    # 3. Extrair o sistema de arquivos raiz
    log_step "Extracting squashfs from $FULL_TEMP_MOUNT_PATH/casper/minimal.standard.live.squashfs to $LIVE_FS_DIR"
    # ALTERE A LINHA ABAIXO:
    # extract_squashfs "$FULL_TEMP_MOUNT_PATH/casper/filesystem.squashfs" "$LIVE_FS_DIR"
    # PARA:
    extract_squashfs "$FULL_TEMP_MOUNT_PATH/casper/minimal.standard.live.squashfs" "$LIVE_FS_DIR"

    # Certifique-se de que o loopback.cfg e outros arquivos de boot importantes estejam no lugar certo
    cp "$TEMP_MOUNT_POINT/md5sum.txt" "$ISO_BUILD_DIR/"
    # A pasta do casper dentro de ISO_BUILD_DIR será atualizada com o novo squashfs

    # 4. Preparar o ambiente chroot (antes de entrar para personalização automática)
    prepare_chroot "$LIVE_FS_DIR"

    # 5. Personalização Automática do Sistema (Este é o ponto chave para seus scripts de personalização)
    log_step "Performing automatic system customization..."
    # Exemplo: Remover Firefox, instalar Neovim
    # Você criaria um script separado, digamos 'customize.sh', e o chamaria aqui.
    # Ex: import "customize.sh" "customization"
    # Ou diretamente aqui:
    # run_in_chroot "$LIVE_FS_DIR" "apt-get update"
    # run_in_chroot "$LIVE_FS_DIR" "apt-get install -y neovim htop git"            # Instala pacotes
    # run_in_chroot "$LIVE_FS_DIR" "apt-get remove --purge -y firefox thunderbird" # Remove pacotes
    # run_in_chroot "$LIVE_FS_DIR" "apt-get autoremove -y && apt-get clean"        # Limpeza
    # run_in_chroot "$LIVE_FS_DIR" "rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*" # Limpeza mais profunda

    # 6. Limpeza do Ambiente Chroot
    clean_chroot "$LIVE_FS_DIR"

    # 7. Reconstrução do Sistema de Arquivos Squashed
    log_step "Removing old filesystem.squashfs and creating new one..."
    sudo rm "$ISO_BUILD_DIR/casper/filesystem.squashfs" # Remove o antigo
    create_squashfs_file "$LIVE_FS_DIR" "$ISO_BUILD_DIR/casper/filesystem.squashfs"

    # 8. Reconstrução da ISO
    create_iso_image "$ISO_BUILD_DIR" "$OUTPUT_DIR/custom_ubuntu.iso" "$ISO_LABEL"

    log_step "ISO build process completed! Your ISO is at $OUTPUT_DIR/custom_ubuntu.iso"

elif [ "$ACTION_CHROOT_MANUAL" == 1 ]; then
    log_step "Entering manual chroot mode..."

    mount_iso "$INPUT_ISO" "$TEMP_MOUNT_POINT"
    extract_squashfs "$TEMP_MOUNT_POINT/casper/filesystem.squashfs" "$LIVE_FS_DIR"
    prepare_chroot "$LIVE_FS_DIR"

    enter_chroot_manual "$LIVE_FS_DIR"

    # Após sair do chroot manual, você pode adicionar a opção de reconstruir a ISO
    # se o usuário fizer modificações. Por enquanto, só limpa.
    clean_chroot "$LIVE_FS_DIR"
    log_step "Manual chroot session finished. You can now rebuild the ISO if needed."

else
    echo "$ERROR_NO_ACTION"
    help
fi

# Limpeza final (sempre tenta desmontar e remover temporários)
log_step "Performing final cleanup..."
unmount_dir "$TEMP_MOUNT_POINT"
sudo rm -rf "$TEMP_MOUNT_POINT" "$LIVE_FS_DIR" "$ISO_BUILD_DIR" # Cuidado ao remover, certifique-se de que não há dados importantes aqui.
log_step "Cleanup complete."

debug "Step 2: Attempting to open UI lib..."
import "ui/open.sh" "ui"