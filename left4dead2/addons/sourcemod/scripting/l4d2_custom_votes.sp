/**
 * ==============================================================================
 * l4d2_custom_votes.sp - Menú de Votaciones Públicas para L4D2 (Mapas, Modos, Dif)
 * ==============================================================================
 * Permite a cualquier jugador escribir !votes, !votemap, !modo, !mapas en chat
 * para iniciar votaciones públicas con menús intuitivos en pantalla.
 * ==============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0"

public Plugin myinfo = 
{
    name = "L4D2 Custom Votes & Map Chooser",
    author = "Fernando / Assistant",
    description = "Public vote menu for maps, game modes, difficulties and round restart.",
    version = PLUGIN_VERSION,
    url = "https://github.com/FernandoGarambelM/ServerLeft"
};

enum VoteType
{
    VOTE_NONE = 0,
    VOTE_MAP,
    VOTE_MODE,
    VOTE_DIFF,
    VOTE_RESTART
};

VoteType g_CurrentVoteType = VOTE_NONE;
char g_sVoteTargetData[64];
char g_sVoteTargetName[64];
int g_iLastVoteTime = 0;
ConVar g_cvVoteCooldown;

public void OnPluginStart()
{
    g_cvVoteCooldown = CreateConVar("l4d2_vote_cooldown", "30.0", "Tiempo de espera en segundos entre votaciones.", FCVAR_NOTIFY, true, 0.0);

    // Comandos de Chat / Consola
    RegConsoleCmd("sm_votes", Cmd_VoteMenu, "Abre el menu de votaciones");
    RegConsoleCmd("sm_vote", Cmd_VoteMenu, "Abre el menu de votaciones");
    RegConsoleCmd("sm_votemap", Cmd_VoteMapMenu, "Abre el menu de votacion de mapas");
    RegConsoleCmd("sm_mapas", Cmd_VoteMapMenu, "Abre el menu de votacion de mapas");
    RegConsoleCmd("sm_modo", Cmd_VoteModeMenu, "Abre el menu de votacion de modo de juego");
    RegConsoleCmd("sm_modos", Cmd_VoteModeMenu, "Abre el menu de votacion de modo de juego");
    RegConsoleCmd("sm_dificultad", Cmd_VoteDiffMenu, "Abre el menu de votacion de dificultad");
    RegConsoleCmd("sm_restart", Cmd_VoteRestart, "Inicia votacion para reiniciar capitulo");

    AutoExecConfig(true, "l4d2_custom_votes");
}

// ------------------------------------------------------------------------------
// Menú Principal
// ------------------------------------------------------------------------------

public Action Cmd_VoteMenu(int client, int args)
{
    if (client == 0 || !IsClientInGame(client))
    {
        ReplyToCommand(client, "[VOTES] Este comando solo se puede usar dentro del juego.");
        return Plugin_Handled;
    }

    ShowMainMenu(client);
    return Plugin_Handled;
}

void ShowMainMenu(int client)
{
    Menu menu = new Menu(Handler_MainMenu);
    menu.SetTitle("★ Menu de Votaciones Servidor ★\nElige que deseas votar:");

    menu.AddItem("map", "1. Votar Cambio de Campaña / Mapa");
    menu.AddItem("mode", "2. Votar Modo de Juego (Coop / Versus / etc)");
    menu.AddItem("diff", "3. Votar Dificultad");
    menu.AddItem("restart", "4. Votar Reiniciar Capitulo");

    menu.ExitButton = true;
    menu.Display(client, 20);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));

        if (StrEqual(info, "map"))
        {
            ShowMapMenu(param1);
        }
        else if (StrEqual(info, "mode"))
        {
            ShowModeMenu(param1);
        }
        else if (StrEqual(info, "diff"))
        {
            ShowDiffMenu(param1);
        }
        else if (StrEqual(info, "restart"))
        {
            StartPublicVote(param1, VOTE_RESTART, "restart", "Reiniciar el Capitulo");
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ------------------------------------------------------------------------------
// Menú de Mapas / Campañas
// ------------------------------------------------------------------------------

public Action Cmd_VoteMapMenu(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        ShowMapMenu(client);
    }
    return Plugin_Handled;
}

void ShowMapMenu(int client)
{
    Menu menu = new Menu(Handler_MapMenu);
    menu.SetTitle("★ Votar Campaña / Mapa ★\nSelecciona la campaña:");

    // Oficiales
    menu.AddItem("c1m1_hotel", "Dead Center (C1)");
    menu.AddItem("c2m1_highway", "Dark Carnival (C2)");
    menu.AddItem("c3m1_plankcountry", "Swamp Fever (C3)");
    menu.AddItem("c4m1_milltown_a", "Hard Rain (C4)");
    menu.AddItem("c5m1_waterfront", "The Parish (C5)");
    menu.AddItem("c6m1_riverbank", "The Passing (C6)");
    menu.AddItem("c7m1_docks", "The Sacrifice (C7)");
    menu.AddItem("c8m1_apartment", "No Mercy (C8)");
    menu.AddItem("c9m1_alleys", "Crash Course (C9)");
    menu.AddItem("c10m1_caves", "Death Toll (C10)");
    menu.AddItem("c11m1_greenhouse", "Dead Air (C11)");
    menu.AddItem("c12m1_hilltop", "Blood Harvest (C12)");
    menu.AddItem("c13m1_alpinecreek", "Cold Stream (C13)");
    menu.AddItem("c14m1_junkyard", "The Last Stand (C14)");

    // Custom / Workshop
    menu.AddItem("Glubtastic", "[Custom] Glubtastic 1");
    menu.AddItem("Glubtastic2_1", "[Custom] Glubtastic 2");
    menu.AddItem("Glubtastic3_1", "[Custom] Glubtastic 3");
    menu.AddItem("glubtastic4_1", "[Custom] Glubtastic 4");
    menu.AddItem("Back4Glub", "[Custom] Back 4 Glub");
    menu.AddItem("anemoia_arcade", "[Custom] Anemoia (Backrooms)");
    menu.AddItem("C1_mario1_1", "[Custom] Left 4 Mario");
    menu.AddItem("yanahuara", "[Custom] Yanahuara");
    menu.AddItem("hehe20_1", "[Custom] Hehe20");

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 25);
}

public int Handler_MapMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char mapCode[64], mapName[64];
        menu.GetItem(param2, mapCode, sizeof(mapCode), _, mapName, sizeof(mapName));

        StartPublicVote(param1, VOTE_MAP, mapCode, mapName);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowMainMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ------------------------------------------------------------------------------
// Menú de Modos de Juego
// ------------------------------------------------------------------------------

public Action Cmd_VoteModeMenu(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        ShowModeMenu(client);
    }
    return Plugin_Handled;
}

void ShowModeMenu(int client)
{
    Menu menu = new Menu(Handler_ModeMenu);
    menu.SetTitle("★ Votar Modo de Juego ★\nSelecciona el modo:");

    menu.AddItem("coop", "Cooperativo (Coop)");
    menu.AddItem("versus", "Enfrentamiento (Versus 8v8)");
    menu.AddItem("survival", "Supervivencia (Survival)");
    menu.AddItem("realism", "Realismo (Realism)");

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 20);
}

public int Handler_ModeMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char modeCode[32], modeName[64];
        menu.GetItem(param2, modeCode, sizeof(modeCode), _, modeName, sizeof(modeName));

        StartPublicVote(param1, VOTE_MODE, modeCode, modeName);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowMainMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ------------------------------------------------------------------------------
// Menú de Dificultades
// ------------------------------------------------------------------------------

public Action Cmd_VoteDiffMenu(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        ShowDiffMenu(client);
    }
    return Plugin_Handled;
}

void ShowDiffMenu(int client)
{
    Menu menu = new Menu(Handler_DiffMenu);
    menu.SetTitle("★ Votar Dificultad ★\nSelecciona la dificultad:");

    menu.AddItem("Easy", "Facil (Easy)");
    menu.AddItem("Normal", "Normal");
    menu.AddItem("Hard", "Avanzado (Hard)");
    menu.AddItem("Impossible", "Experto (Impossible)");

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, 20);
}

public int Handler_DiffMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char diffCode[32], diffName[64];
        menu.GetItem(param2, diffCode, sizeof(diffCode), _, diffName, sizeof(diffName));

        StartPublicVote(param1, VOTE_DIFF, diffCode, diffName);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowMainMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public Action Cmd_VoteRestart(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        StartPublicVote(client, VOTE_RESTART, "restart", "Reiniciar el Capitulo");
    }
    return Plugin_Handled;
}

// ------------------------------------------------------------------------------
// Controlador de la Votación Pública
// ------------------------------------------------------------------------------

void StartPublicVote(int initiator, VoteType type, const char[] data, const char[] name)
{
    if (IsVoteInProgress())
    {
        PrintToChat(initiator, "\x04[VOTES]\x01 Ya hay otra votacion en curso. Espera a que termine.");
        return;
    }

    int currentTime = GetTime();
    int cooldown = g_cvVoteCooldown.IntValue;
    if (currentTime - g_iLastVoteTime < cooldown)
    {
        int remaining = cooldown - (currentTime - g_iLastVoteTime);
        PrintToChat(initiator, "\x04[VOTES]\x01 Debes esperar \x03%d segundos\x01 antes de iniciar otra votacion.", remaining);
        return;
    }

    g_CurrentVoteType = type;
    strcopy(g_sVoteTargetData, sizeof(g_sVoteTargetData), data);
    strcopy(g_sVoteTargetName, sizeof(g_sVoteTargetName), name);

    char initiatorName[64];
    GetClientName(initiator, initiatorName, sizeof(initiatorName));

    Menu voteMenu = new Menu(Handler_VoteCallback);
    
    char title[128];
    switch (type)
    {
        case VOTE_MAP:
            Format(title, sizeof(title), "¿Cambiar a %s?\nIniciada por: %s", name, initiatorName);
        case VOTE_MODE:
            Format(title, sizeof(title), "¿Cambiar modo a %s?\nIniciada por: %s", name, initiatorName);
        case VOTE_DIFF:
            Format(title, sizeof(title), "¿Cambiar dificultad a %s?\nIniciada por: %s", name, initiatorName);
        case VOTE_RESTART:
            Format(title, sizeof(title), "¿Reiniciar el capitulo actual?\nIniciada por: %s", initiatorName);
    }
    
    voteMenu.SetTitle(title);
    voteMenu.AddItem("yes", "Si");
    voteMenu.AddItem("no", "No");
    voteMenu.ExitButton = false;

    PrintToChatAll("\x04[VOTES]\x03 %s\x01 inicio una votacion: \x05%s", initiatorName, title);

    voteMenu.DisplayVoteToAll(18);
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_VoteEnd)
    {
        // param1 = item ganador (0 = yes, 1 = no)
        // param2 = total de votos
        if (param1 == 0) // "yes" ganó
        {
            PrintToChatAll("\x04[VOTES]\x01 La votacion ha sido \x05APROBADA\x01.");
            ExecuteVoteAction();
        }
        else
        {
            PrintToChatAll("\x04[VOTES]\x01 La votacion ha sido \x02RECHAZADA\x01.");
        }
        g_iLastVoteTime = GetTime();
        g_CurrentVoteType = VOTE_NONE;
    }
    else if (action == MenuAction_VoteCancel)
    {
        PrintToChatAll("\x04[VOTES]\x01 La votacion fue cancelada por falta de participacion.");
        g_iLastVoteTime = GetTime();
        g_CurrentVoteType = VOTE_NONE;
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void ExecuteVoteAction()
{
    switch (g_CurrentVoteType)
    {
        case VOTE_MAP:
        {
            PrintToChatAll("\x04[VOTES]\x01 Cambiando mapa a \x03%s\x01 en 3 segundos...", g_sVoteTargetName);
            CreateTimer(3.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        case VOTE_MODE:
        {
            PrintToChatAll("\x04[VOTES]\x01 Modo cambiado a \x03%s\x01. Recargando partida...", g_sVoteTargetName);
            ServerCommand("sm_cvar mp_gamemode %s", g_sVoteTargetData);
            CreateTimer(3.0, Timer_ReloadCurrentMap, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        case VOTE_DIFF:
        {
            PrintToChatAll("\x04[VOTES]\x01 Dificultad cambiada a \x03%s\x01.", g_sVoteTargetName);
            ServerCommand("sm_cvar z_difficulty %s", g_sVoteTargetData);
        }
        case VOTE_RESTART:
        {
            PrintToChatAll("\x04[VOTES]\x01 Reiniciando el capitulo...");
            ServerCommand("sm_cvar mp_restartgame 1");
        }
    }
}

public Action Timer_ChangeMap(Handle timer)
{
    ForceChangeLevel(g_sVoteTargetData, "Custom vote passed");
    return Plugin_Stop;
}

public Action Timer_ReloadCurrentMap(Handle timer)
{
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    ForceChangeLevel(currentMap, "Game mode changed by vote");
    return Plugin_Stop;
}
