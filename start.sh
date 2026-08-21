#!/usr/bin/env bash
# ==============================================================================
# start.sh - Panel de Control y Lanzador para L4D2 Dedicated Server
# ==============================================================================
# Uso:
#   ./start.sh                  -> Menú interactivo
#   ./start.sh start [modo] [mapa] [dif] -> Inicia en segundo plano (screen)
#   ./start.sh fg [modo] [mapa] [dif]    -> Inicia en primer plano (consola en vivo)
#   ./start.sh stop             -> Detiene el servidor
#   ./start.sh restart [...]    -> Reinicia el servidor
#   ./start.sh console          -> Accede a la consola del servidor en vivo
#   ./start.sh status           -> Muestra el estado del servidor
#   ./start.sh help             -> Muestra la ayuda
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SCREEN_NAME="l4d2_server"
PORT="27015"
TICKRATE="60"
MAX_PLAYERS="31"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# Funciones Utilitarias
# ------------------------------------------------------------------------------

check_screen() {
    if ! command -v screen &> /dev/null; then
        echo -e "${YELLOW}Instalando 'screen' para ejecución en segundo plano...${NC}"
        if command -v sudo &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq screen
        else
            echo -e "${RED}ERROR: 'screen' no está instalado. Ejecuta: apt install screen${NC}"
            exit 1
        fi
    fi
}

is_running() {
    if command -v screen &> /dev/null && screen -list 2>/dev/null | grep -q "\.${SCREEN_NAME}[[:space:]]"; then
        return 0
    elif pgrep -f "srcds_linux.*left4dead2" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

get_pid() {
    pgrep -f "srcds_linux.*left4dead2" | head -n 1
}

# ------------------------------------------------------------------------------
# Comandos de Gestión
# ------------------------------------------------------------------------------

status_server() {
    echo -e "${CYAN}=== Estado del Servidor Left 4 Dead 2 ===${NC}"
    if is_running; then
        local pid=$(get_pid)
        echo -e "Estado:  ${GREEN}${BOLD}EN LÍNEA (Activo)${NC}"
        [ -n "$pid" ] && echo -e "PID:     ${YELLOW}$pid${NC}"
        echo -e "Sesión:  ${CYAN}$SCREEN_NAME${NC}"
        echo -e "Puerto:  ${YELLOW}$PORT (UDP)${NC}"
        echo ""
        echo -e "Para ver la consola en vivo:  ${BOLD}./start.sh console${NC}"
        echo -e "Para detener el servidor:      ${BOLD}./start.sh stop${NC}"
    else
        echo -e "Estado:  ${RED}${BOLD}DETENIDO (Apagado)${NC}"
        echo ""
        echo -e "Para iniciarlo:  ${BOLD}./start.sh${NC}  o  ${BOLD}./start.sh start${NC}"
    fi
}

stop_server() {
    echo -e "${YELLOW}Deteniendo el servidor L4D2...${NC}"
    if is_running; then
        # Intentar comando de salida limpio por screen
        screen -S "$SCREEN_NAME" -X stuff "quit$(printf '\r')" 2>/dev/null || true
        sleep 2
        
        # Si aún sigue corriendo, terminar proceso
        if is_running; then
            pkill -f "srcds_linux.*left4dead2" 2>/dev/null || true
            sleep 1
        fi
        
        # Limpiar screen si quedó huérfano
        screen -wipe 2>/dev/null || true
        
        if is_running; then
            echo -e "${RED}Forzando detención...${NC}"
            pkill -9 -f "srcds_linux.*left4dead2" 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✓ Servidor detenido correctamente.${NC}"
    else
        echo -e "${YELLOW}El servidor ya está detenido.${NC}"
    fi
}

attach_console() {
    if is_running; then
        echo -e "${CYAN}Conectando a la consola del servidor...${NC}"
        echo -e "${YELLOW}(Para salir de la consola sin apagar el servidor, presiona: Ctrl + A luego D)${NC}"
        sleep 1
        screen -r "$SCREEN_NAME"
    else
        echo -e "${RED}ERROR: El servidor no está corriendo.${NC}"
        echo -e "Inícialo con: ${BOLD}./start.sh${NC}"
    fi
}

launch_server() {
    local mode="$1"
    local map="$2"
    local diff="$3"
    local background="$4"

    # Valores por defecto
    [ -z "$mode" ] && mode="coop"
    [ -z "$map" ] && map="c1m1_hotel"
    [ -z "$diff" ] && diff="Normal"

    if is_running; then
        echo -e "${YELLOW}El servidor ya está corriendo.${NC}"
        echo -e "Usa ${BOLD}./start.sh console${NC} o ${BOLD}./start.sh restart${NC}."
        exit 0
    fi

    # Verificar binario
    if [ ! -f "./srcds_run" ]; then
        echo -e "${RED}ERROR: No se encontró ./srcds_run. ¿Ejecutaste ./install.sh primero?${NC}"
        exit 1
    fi
    chmod +x ./srcds_run ./srcds_linux 2>/dev/null || true

    local CMD="./srcds_run -game left4dead2 -console -port $PORT +sv_setmax $MAX_PLAYERS +sv_maxplayers $MAX_PLAYERS -tickrate $TICKRATE +map $map +mp_gamemode $mode +z_difficulty $diff"

    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}${BOLD}  Iniciando Left 4 Dead 2 Dedicated Server${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo -e "Modo:        ${CYAN}$mode${NC}"
    echo -e "Mapa Inicial:${CYAN}$map${NC}"
    echo -e "Dificultad:  ${CYAN}$diff${NC}"
    echo -e "Tickrate:    ${CYAN}${TICKRATE} tick${NC}"
    echo -e "Slots Max:   ${CYAN}${MAX_PLAYERS} slots${NC}"
    echo -e "Puerto:      ${CYAN}$PORT UDP${NC}"
    echo -e "${GREEN}=============================================${NC}"

    if [ "$background" = "true" ]; then
        check_screen
        echo -e "${YELLOW}Iniciando en segundo plano (sesión screen: $SCREEN_NAME)...${NC}"
        screen -dmS "$SCREEN_NAME" bash -c "$CMD"
        sleep 2
        if is_running; then
            echo -e "${GREEN}✓ Servidor iniciado con éxito en segundo plano.${NC}"
            echo ""
            echo -e "Comandos útiles:"
            echo -e "  - Ver consola:   ${CYAN}./start.sh console${NC}"
            echo -e "  - Ver estado:    ${CYAN}./start.sh status${NC}"
            echo -e "  - Detener:       ${CYAN}./start.sh stop${NC}"
            echo -e "  - Reiniciar:     ${CYAN}./start.sh restart${NC}"
        else
            echo -e "${RED}ERROR: El servidor no pudo iniciar. Revisa los logs.${NC}"
        fi
    else
        echo -e "${YELLOW}Iniciando en primer plano... (Ctrl+C para salir)${NC}"
        exec $CMD
    fi
}

# ------------------------------------------------------------------------------
# Menú Interactivo
# ------------------------------------------------------------------------------

interactive_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗ "
    echo "  ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗"
    echo "  ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝"
    echo "  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗"
    echo "  ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║"
    echo "  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝"
    echo "        Left 4 Dead 2 - Control Manager"
    echo -e "${NC}"

    if is_running; then
        echo -e "Estado Actual: ${GREEN}${BOLD}● EN LÍNEA${NC} (PID: $(get_pid))"
        echo ""
        echo -e "  ${BOLD}[1]${NC} ${CYAN}Entrar a la Consola en Vivo${NC}"
        echo -e "  ${BOLD}[2]${NC} ${RED}Detener el Servidor${NC}"
        echo -e "  ${BOLD}[3]${NC} ${YELLOW}Reiniciar el Servidor${NC}"
        echo -e "  ${BOLD}[4]${NC} Ver Estado y Estadísticas"
        echo -e "  ${BOLD}[0]${NC} Salir"
        echo ""
        read -p "Selecciona una opción [0-4]: " opc
        case "$opc" in
            1) attach_console ;;
            2) stop_server ;;
            3) stop_server && sleep 1 && interactive_launch ;;
            4) status_server ;;
            *) exit 0 ;;
        esac
    else
        echo -e "Estado Actual: ${RED}${BOLD}○ DETENIDO${NC}"
        echo ""
        echo -e "  ${BOLD}[1]${NC} ${GREEN}Iniciar Servidor (Asistente de configuración)${NC}"
        echo -e "  ${BOLD}[2]${NC} ${GREEN}Iniciar Rápido (Dead Center - Coop - Normal)${NC}"
        echo -e "  ${BOLD}[3]${NC} ${GREEN}Iniciar Rápido (Dead Center - Versus 8v8)${NC}"
        echo -e "  ${BOLD}[4]${NC} ${GREEN}Iniciar Rápido (Glubtastic 1)${NC}"
        echo -e "  ${BOLD}[5]${NC} ${GREEN}Iniciar Rápido (Glubtastic 2)${NC}"
        echo -e "  ${BOLD}[6]${NC} ${GREEN}Iniciar Rápido (Glubtastic 3)${NC}"
        echo -e "  ${BOLD}[7]${NC} ${GREEN}Iniciar Rápido (Glubtastic 4)${NC}"
        echo -e "  ${BOLD}[8]${NC} ${GREEN}Iniciar Rápido (Anemoia - Backrooms)${NC}"
        echo -e "  ${BOLD}[0]${NC} Salir"
        echo ""
        read -p "Selecciona una opción [0-8]: " opc
        case "$opc" in
            1) interactive_launch ;;
            2) launch_server "coop" "c1m1_hotel" "Normal" "true" ;;
            3) launch_server "versus" "c1m1_hotel" "Normal" "true" ;;
            4) launch_server "coop" "Glubtastic" "Normal" "true" ;;
            5) launch_server "coop" "Glubtastic2_1" "Normal" "true" ;;
            6) launch_server "coop" "Glubtastic3_1" "Normal" "true" ;;
            7) launch_server "coop" "glubtastic4_1" "Normal" "true" ;;
            8) launch_server "coop" "anemoia_1" "Normal" "true" ;;
            *) exit 0 ;;
        esac
    fi
}

interactive_launch() {
    echo ""
    echo -e "${YELLOW}=== Paso 1: Modo de Juego ===${NC}"
    echo "  [1] Cooperativo (coop)"
    echo "  [2] Enfrentamiento (versus)"
    echo "  [3] Supervivencia (survival)"
    echo "  [4] Realismo (realism)"
    read -p "Elige el modo [1-4, defecto: 1]: " m_opt
    case "$m_opt" in
        2) SEL_MODE="versus" ;;
        3) SEL_MODE="survival" ;;
        4) SEL_MODE="realism" ;;
        *) SEL_MODE="coop" ;;
    esac

    echo ""
    echo -e "${YELLOW}=== Paso 2: Campaña / Mapa Inicial ===${NC}"
    echo -e "${CYAN}-- Campañas Oficiales --${NC}"
    echo "  [1]  Dead Center (c1m1_hotel)"
    echo "  [2]  Dark Carnival (c2m1_highway)"
    echo "  [3]  Swamp Fever (c3m1_plankcountry)"
    echo "  [4]  Hard Rain (c4m1_milltown_a)"
    echo "  [5]  The Parish (c5m1_waterfront)"
    echo "  [6]  The Passing (c6m1_riverbank)"
    echo "  [7]  The Sacrifice (c7m1_docks)"
    echo "  [8]  No Mercy (c8m1_apartment)"
    echo "  [9]  Crash Course (c9m1_alleys)"
    echo "  [10] Death Toll (c10m1_caves)"
    echo "  [11] Dead Air (c11m1_greenhouse)"
    echo "  [12] Blood Harvest (c12m1_hilltop)"
    echo "  [13] Cold Stream (c13m1_alpinecreek)"
    echo "  [14] The Last Stand (c14m1_junkyard)"
    echo -e "${CYAN}-- Campañas Custom / Workshop --${NC}"
    echo "  [15] Glubtastic 1 (Glubtastic)"
    echo "  [16] Glubtastic 2 (Glubtastic2_1)"
    echo "  [17] Glubtastic 3 (Glubtastic3_1)"
    echo "  [18] Glubtastic 4 (glubtastic4_1)"
    echo "  [19] Glubtastic: Back 4 Glub (Back4Glub)"
    echo "  [20] Anemoia - Backrooms (anemoia_1)"
    echo "  [21] Left 4 Mario (C1_mario1_1)"
    echo "  [22] Yanahuara (yanahuara)"
    echo "  [23] Hehe20 (hehe20_1)"
    echo "  [24] Escribir mapa manualmente"
    read -p "Elige la campaña [1-24, defecto: 1]: " map_opt
    case "$map_opt" in
        1)  SEL_MAP="c1m1_hotel" ;;
        2)  SEL_MAP="c2m1_highway" ;;
        3)  SEL_MAP="c3m1_plankcountry" ;;
        4)  SEL_MAP="c4m1_milltown_a" ;;
        5)  SEL_MAP="c5m1_waterfront" ;;
        6)  SEL_MAP="c6m1_riverbank" ;;
        7)  SEL_MAP="c7m1_docks" ;;
        8)  SEL_MAP="c8m1_apartment" ;;
        9)  SEL_MAP="c9m1_alleys" ;;
        10) SEL_MAP="c10m1_caves" ;;
        11) SEL_MAP="c11m1_greenhouse" ;;
        12) SEL_MAP="c12m1_hilltop" ;;
        13) SEL_MAP="c13m1_alpinecreek" ;;
        14) SEL_MAP="c14m1_junkyard" ;;
        15) SEL_MAP="Glubtastic" ;;
        16) SEL_MAP="Glubtastic2_1" ;;
        17) SEL_MAP="Glubtastic3_1" ;;
        18) SEL_MAP="glubtastic4_1" ;;
        19) SEL_MAP="Back4Glub" ;;
        20) SEL_MAP="anemoia_1" ;;
        21) SEL_MAP="C1_mario1_1" ;;
        22) SEL_MAP="yanahuara" ;;
        23) SEL_MAP="hehe20_1" ;;
        24) 
            read -p "Ingresa el nombre del archivo bsp (sin .bsp): " custom_map
            SEL_MAP="$custom_map"
            ;;
        *)  SEL_MAP="c1m1_hotel" ;;
    esac

    echo ""
    echo -e "${YELLOW}=== Paso 3: Dificultad ===${NC}"
    echo "  [1] Normal"
    echo "  [2] Avanzado (Hard)"
    echo "  [3] Experto (Impossible)"
    echo "  [4] Fácil (Easy)"
    read -p "Elige la dificultad [1-4, defecto: 1]: " diff_opt
    case "$diff_opt" in
        2) SEL_DIFF="Hard" ;;
        3) SEL_DIFF="Impossible" ;;
        4) SEL_DIFF="Easy" ;;
        *) SEL_DIFF="Normal" ;;
    esac

    echo ""
    echo -e "${YELLOW}=== Paso 4: Modo de Ejecución ===${NC}"
    echo "  [1] Segundo plano con Screen (Recomendado - Puedes cerrar la terminal)"
    echo "  [2] Primer plano (Consola directa en vivo)"
    read -p "Elige ejecución [1-2, defecto: 1]: " exec_opt
    if [ "$exec_opt" = "2" ]; then
        launch_server "$SEL_MODE" "$SEL_MAP" "$SEL_DIFF" "false"
    else
        launch_server "$SEL_MODE" "$SEL_MAP" "$SEL_DIFF" "true"
    fi
}

show_help() {
    echo -e "${CYAN}Uso de start.sh:${NC}"
    echo -e "  ${BOLD}./start.sh${NC}                           Abre el menú interactivo"
    echo -e "  ${BOLD}./start.sh start [modo] [mapa] [dif]${NC} Inicia en background con screen"
    echo -e "  ${BOLD}./start.sh fg [modo] [mapa] [dif]${NC}    Inicia en foreground (consola en vivo)"
    echo -e "  ${BOLD}./start.sh stop${NC}                      Detiene el servidor"
    echo -e "  ${BOLD}./start.sh restart [modo] [mapa]${NC}     Reinicia el servidor"
    echo -e "  ${BOLD}./start.sh console${NC} (o attach)        Abre la consola en vivo del servidor"
    echo -e "  ${BOLD}./start.sh status${NC}                     Muestra el estado actual del proceso"
    echo ""
    echo -e "Ejemplos:"
    echo -e "  ${CYAN}./start.sh start coop c1m1_hotel Normal${NC}"
    echo -e "  ${CYAN}./start.sh start versus c2m1_highway Normal${NC}"
    echo -e "  ${CYAN}./start.sh start coop Glubtastic2_1 Impossible${NC}"
}

# ------------------------------------------------------------------------------
# Entrada Principal
# ------------------------------------------------------------------------------

ACTION="${1:-menu}"
shift 2>/dev/null || true

case "$ACTION" in
    menu)
        interactive_menu
        ;;
    start)
        launch_server "$1" "$2" "$3" "true"
        ;;
    fg|foreground|run)
        launch_server "$1" "$2" "$3" "false"
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 1
        launch_server "$1" "$2" "$3" "true"
        ;;
    console|attach)
        attach_console
        ;;
    status)
        status_server
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo -e "${RED}Comando desconocido: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
