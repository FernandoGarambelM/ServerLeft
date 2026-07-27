#!/usr/bin/env bash
# =============================================
# install.sh - Left 4 Dead 2 Dedicated Server
# =============================================
# Uso:
#   1. git clone https://github.com/FernandoGarambelM/ServerLeft.git
#   2. cd ServerLeft
#   3. chmod +x install.sh
#   4. ./install.sh
# =============================================

set -e

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEAMCMD_DIR="$INSTALL_DIR/steamcmd"
L4D2_APP_ID="222860"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "============================================="
echo "  L4D2 Dedicated Server - Instalador"
echo "============================================="
echo -e "${NC}"

# -----------------------------------------------
# PASO 1: Dependencias del sistema
# -----------------------------------------------
echo -e "${YELLOW}[1/5] Verificando dependencias...${NC}"

if ! command -v tar &> /dev/null; then
    echo -e "${RED}ERROR: 'tar' no encontrado. Instálalo con: sudo apt install tar${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo -e "${RED}ERROR: Necesitas 'curl' o 'wget'. Instálalo con: sudo apt install curl${NC}"
    exit 1
fi

# lib32 necesario para SteamCMD en Ubuntu/Debian
if ! dpkg -l | grep -q "lib32gcc" 2>/dev/null; then
    echo -e "${YELLOW}Instalando lib32gcc (necesario para SteamCMD)...${NC}"
    sudo apt-get install -y lib32gcc-s1 2>/dev/null || \
    sudo apt-get install -y lib32gcc1 2>/dev/null || \
    echo -e "${YELLOW}AVISO: No se pudo instalar lib32gcc automáticamente. Puede que SteamCMD falle.${NC}"
fi

echo -e "${GREEN}✓ Dependencias OK${NC}"

# -----------------------------------------------
# PASO 2: Descargar e instalar SteamCMD
# -----------------------------------------------
echo -e "${YELLOW}[2/5] Instalando SteamCMD...${NC}"

mkdir -p "$STEAMCMD_DIR"
cd "$STEAMCMD_DIR"

if [ ! -f "steamcmd.sh" ]; then
    echo "Descargando SteamCMD..."
    if command -v curl &> /dev/null; then
        curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz
    else
        wget -q "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -O steamcmd_linux.tar.gz
    fi
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    echo -e "${GREEN}✓ SteamCMD descargado${NC}"
else
    echo -e "${GREEN}✓ SteamCMD ya existe, saltando descarga${NC}"
fi

cd "$INSTALL_DIR"

# -----------------------------------------------
# PASO 3: Instalar/actualizar L4D2 Dedicated Server
# -----------------------------------------------
echo -e "${YELLOW}[3/5] Instalando L4D2 Dedicated Server via SteamCMD...${NC}"
echo -e "${CYAN}(Esto puede tardar varios minutos dependiendo de tu conexión)${NC}"

echo -e "${YELLOW}Valve ha bloqueado recientemente las descargas anónimas para servidores de L4D2.${NC}"
echo -e "${YELLOW}Necesitas usar tu cuenta de Steam que tenga el juego comprado.${NC}"
read -p "Ingresa tu nombre de usuario de Steam: " STEAM_USER

"$STEAMCMD_DIR/steamcmd.sh" \
    +force_install_dir "$INSTALL_DIR" \
    +login "$STEAM_USER" \
    +app_update "$L4D2_APP_ID" validate \
    +quit

echo -e "${GREEN}✓ L4D2 instalado/actualizado${NC}"

# -----------------------------------------------
# PASO 4: Instalar MetaMod:Source + SourceMod
# -----------------------------------------------
echo -e "${YELLOW}[4/5] Instalando MetaMod:Source y SourceMod...${NC}"

METAMOD_LATEST=$(curl -s https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux || echo "mmsource-1.12.0-git1211-linux.tar.gz")
METAMOD_URL="https://mms.alliedmods.net/mmsdrop/1.12/$METAMOD_LATEST"
SOURCEMOD_LATEST=$(curl -s https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux || echo "sourcemod-1.12.0-git7246-linux.tar.gz")
SOURCEMOD_URL="https://sm.alliedmods.net/smdrop/1.12/$SOURCEMOD_LATEST"

TMP_DIR=$(mktemp -d)

echo "Descargando MetaMod:Source..."
if command -v curl &> /dev/null; then
    curl -fsSL "$METAMOD_URL" -o "$TMP_DIR/metamod.tar.gz" 2>/dev/null || \
    { echo -e "${YELLOW}AVISO: No se pudo descargar MetaMod automáticamente.${NC}"
      echo -e "${YELLOW}Descárgalo manualmente de: https://www.sourcemm.net/downloads.php?branch=stable${NC}"
      echo -e "${YELLOW}Y extráelo en: $INSTALL_DIR/left4dead2/${NC}"; }
else
    wget -q "$METAMOD_URL" -O "$TMP_DIR/metamod.tar.gz" 2>/dev/null || \
    { echo -e "${YELLOW}AVISO: No se pudo descargar MetaMod automáticamente.${NC}"; }
fi

if [ -f "$TMP_DIR/metamod.tar.gz" ]; then
    tar -xzf "$TMP_DIR/metamod.tar.gz" -C "$INSTALL_DIR/left4dead2/"
    echo -e "${GREEN}✓ MetaMod:Source instalado${NC}"
fi

echo "Descargando SourceMod..."
if command -v curl &> /dev/null; then
    curl -fsSL "$SOURCEMOD_URL" -o "$TMP_DIR/sourcemod.tar.gz" 2>/dev/null || \
    { echo -e "${YELLOW}AVISO: No se pudo descargar SourceMod automáticamente.${NC}"
      echo -e "${YELLOW}Descárgalo manualmente de: https://www.sourcemod.net/downloads.php?branch=stable${NC}"
      echo -e "${YELLOW}Y extráelo en: $INSTALL_DIR/left4dead2/${NC}"; }
else
    wget -q "$SOURCEMOD_URL" -O "$TMP_DIR/sourcemod.tar.gz" 2>/dev/null || \
    { echo -e "${YELLOW}AVISO: No se pudo descargar SourceMod automáticamente.${NC}"; }
fi

if [ -f "$TMP_DIR/sourcemod.tar.gz" ]; then
    tar -xzf "$TMP_DIR/sourcemod.tar.gz" -C "$INSTALL_DIR/left4dead2/"
    echo -e "${GREEN}✓ SourceMod instalado${NC}"
fi

rm -rf "$TMP_DIR"

# -----------------------------------------------
# PASO 5: Recordatorio - Workshop Addons
# -----------------------------------------------
echo -e "${YELLOW}[5/5] Workshop Addons (acción manual requerida)${NC}"
echo ""
echo -e "${CYAN}Los siguientes addons del Workshop NO están en el repositorio.${NC}"
echo -e "${CYAN}Descárgalos y colócalos en: ${INSTALL_DIR}/left4dead2/addons/${NC}"
echo ""

if [ -f "$INSTALL_DIR/workshop_addons.txt" ]; then
    echo "IDs de addons a descargar:"
    grep -v '^#' "$INSTALL_DIR/workshop_addons.txt" | grep -v '^$' | while read -r line; do
        ID=$(echo "$line" | awk '{print $1}')
        if [ -n "$ID" ]; then
            if [ -f "$INSTALL_DIR/left4dead2/addons/${ID}.vpk" ]; then
                echo -e "  ${GREEN}✓ ${ID} (ya existe)${NC}"
            else
                echo -e "  ${RED}✗ ${ID}${NC} - https://steamcommunity.com/sharedfiles/filedetails/?id=${ID}"
                # Intentar descargar via SteamCMD
                echo "    Descargando via SteamCMD..."
                "$STEAMCMD_DIR/steamcmd.sh" \
                    +login "$STEAM_USER" \
                    +workshop_download_item 550 "$ID" \
                    +quit 2>/dev/null || true
                # Buscar el VPK descargado y moverlo
                WORKSHOP_PATH="$INSTALL_DIR/steamapps/workshop/content/550/$ID"
                if [ -d "$WORKSHOP_PATH" ]; then
                    VPK_FILE=$(find "$WORKSHOP_PATH" -name "*.vpk" | head -1)
                    if [ -n "$VPK_FILE" ]; then
                        cp "$VPK_FILE" "$INSTALL_DIR/left4dead2/addons/${ID}.vpk"
                        echo -e "    ${GREEN}✓ ${ID} descargado y copiado${NC}"
                    fi
                fi
            fi
        fi
    done
fi

# -----------------------------------------------
# FIN
# -----------------------------------------------
echo ""
echo -e "${GREEN}============================================="
echo -e "  ✓ Instalación completada"
echo -e "=============================================${NC}"
echo ""
echo -e "Para iniciar el servidor:"
echo -e "  ${CYAN}./srcds_run -game left4dead2 -console -port 27015 +sv_setmax 16 -tickrate 60 +map c1m1_hotel${NC}"
echo ""
echo -e "Si hay addons del Workshop que faltan, edita y ejecuta:"
echo -e "  ${CYAN}cat workshop_addons.txt${NC}"
echo ""
