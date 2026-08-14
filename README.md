# Left 4 Dead 2 Dedicated Server - ServerLeft

Servidor dedicado de Left 4 Dead 2 para Linux optimizado para 16 jugadores (Coop / Versus 8v8), Tickrate 60, SourceMod 1.12, MetaMod, soporte de campañas personalizadas (Glubtastic 1-4, etc.) y panel de control por terminal con menú interactivo.

---

## 🚀 Inicio Rápido

### 1. Iniciar con el Panel Interactivo
Simplemente ejecuta:
```bash
./start.sh
```
Aparecerá un menú visual en tu terminal para elegir el modo de juego (*Coop, Versus, Survival*), la campaña (*Oficiales y Glubtastic 1, 2, 3, 4*), la dificultad y si deseas ejecutarlo en segundo plano (*Background con Screen*).

### 2. Comandos de Gestión Directa
Puedes controlar el servidor rápidamente desde la terminal:

```bash
# Iniciar en segundo plano (Background)
./start.sh start coop c1m1_hotel Normal
./start.sh start versus c2m1_highway Normal
./start.sh start coop Glubtastic2_1 Impossible

# Ver el estado del servidor (PID, puerto, uptime)
./start.sh status

# Conectarte a la consola del servidor en vivo
./start.sh console
# (Para salir de la consola sin apagar el servidor, presiona: Ctrl + A luego D)

# Detener el servidor
./start.sh stop

# Reiniciar el servidor
./start.sh restart coop c1m1_hotel
```

---

## 🗳️ Sistema de Votaciones In-Game (Para Todos los Jugadores)

Cualquier jugador puede abrir el menú de votaciones escribiendo en el chat:
* `!votes` o `!vote` : Abre el menú principal de votaciones.
* `!votemap` o `!mapas` : Abre directamente la lista de campañas para votar.
* `!modo` o `!modos` : Votar para cambiar de modo (*Coop / Versus 8v8 / Supervivencia*).
* `!dificultad` : Votar cambio de dificultad (*Fácil, Normal, Avanzado, Experto*).
* `!restart` : Votar para reiniciar el capítulo actual.

### Campañas disponibles para votación:
* **Oficiales**: Dead Center, Dark Carnival, Swamp Fever, Hard Rain, The Parish, The Passing, The Sacrifice, No Mercy, Crash Course, Death Toll, Dead Air, Blood Harvest, Cold Stream, The Last Stand.
* **Custom**: Glubtastic 1, Glubtastic 2, Glubtastic 3, Glubtastic 4, Back 4 Glub, Left 4 Mario, Yanahuara, Hehe20.

---

## 👑 Menú de Administrador Inmediato (`!admin`)

Los administradores pueden cambiar mapas y modos instantáneamente sin someterlo a votación:

1. Agrega tu SteamID en `left4dead2/addons/sourcemod/configs/admins_simple.ini`:
   ```ini
   "STEAM_1:X:XXXXX" "99:z"
   ```
2. Dentro del juego, abre la consola y escribe `sm_admin` o escribe en el chat:
   ```text
   !admin
   ```
3. En el menú encontrarás las opciones de:
   * **Gestión del Servidor**: Cambiar Modo de Juego (*Coop/Versus*), Cambiar Dificultad, Reiniciar Ronda, Crear Bot Superviviente.
   * **Comandos de Mapa**: Cambiar de Campaña inmediatamente.
   * **Gestión de Jugadores**: Kick, Ban, Mute, Slay, Teleport.

---

## 🛠️ Instalación Inicial

Si estás configurando una máquina nueva o servidor en la nube:
```bash
git clone https://github.com/FernandoGarambelM/ServerLeft.git
cd ServerLeft
chmod +x install.sh start.sh
./install.sh
```
