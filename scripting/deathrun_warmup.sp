#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
    name = "Deathrun Warmup",
    author = "Ilusion9",
    description = "Warmup for deathrun",
    version = "1.1",
    url = "https://github.com/Ilusion9/"
};

Handle g_Timer_Warmup;
Handle g_Hud_Synchronizer;

ConVar g_Cvar_RespawnDeathCT;
ConVar g_Cvar_WarmupDuration;
ConVar g_Cvar_HideWorldKills;
ConVar g_Cvar_ShowHudTimeleft;

int g_WarmupTimeLeft;

public void OnPluginStart()
{
	LoadTranslations("deathrun_warmup.phrases");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	g_Cvar_RespawnDeathCT = FindConVar("mp_respawn_on_death_ct");
	
	g_Cvar_WarmupDuration = CreateConVar("dr_warmup_duration", "30", "How long the warmup period lasts?", 0, true, 0.0);
	g_Cvar_HideWorldKills = CreateConVar("dr_warmup_hide_world_kills", "1", "Hide world kills from killfeed in warmup period?", 0, true, 0.0, true, 1.0);
	g_Cvar_ShowHudTimeleft = CreateConVar("dr_warmup_timeleft_hud", "2", "Show the warmup's timeleft in hud? (0 - no, 1 - hint, 2 - hud)", 0, true, 0.0, true, 2.0);
	
	g_Hud_Synchronizer = CreateHudSynchronizer();
}

public void OnMapEnd()
{
	delete g_Timer_Warmup;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_Timer_Warmup || !g_Cvar_HideWorldKills.BoolValue || event.GetInt("attacker"))
	{
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != CS_TEAM_CT)
	{
		return;
	}

	event.BroadcastDisabled = true;
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	event.FireToClient(client);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_Timer_Warmup;

	if (GameRules_GetProp("m_bWarmupPeriod") || !g_Cvar_WarmupDuration.BoolValue)
	{
		return;
	}
	
	g_WarmupTimeLeft = g_Cvar_WarmupDuration.IntValue;
	g_Cvar_RespawnDeathCT.IntValue = 1;
	
	g_Timer_Warmup = CreateTimer(1.0, Timer_HandleWarmup, _, TIMER_REPEAT);
	PrintToChatAll(" \x04[DR]\x01 %t", "Warmup Chat Start");
}

public Action Timer_HandleWarmup(Handle timer, any data) 
{
	if (!g_WarmupTimeLeft)
	{		
		switch (g_Cvar_ShowHudTimeleft.IntValue)
		{
			case 1:
			{
				PrintHintTextToAll("%t", "Warmup Hud End");
			}
			
			case 2:
			{
				if (g_Hud_Synchronizer)
				{
					SetHudTextParams(-1.0, 0.3, 3.20, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
					ShowSyncHudTextToAll(g_Hud_Synchronizer, "%t", "Warmup Hud End");
				}
			}
		}
		
		PrintToChatAll(" \x04[DR]\x01 %t", "Warmup Chat End");
		g_Cvar_RespawnDeathCT.IntValue = 0;
		
		g_Timer_Warmup = null;
		return Plugin_Stop;
	}
	
	switch (g_Cvar_ShowHudTimeleft.IntValue)
	{
		case 1:
		{
			PrintHintTextToAll("%t", "Warmup Hud Timeleft", g_WarmupTimeLeft / 60, g_WarmupTimeLeft % 60);
		}
		
		case 2:
		{
			if (g_Hud_Synchronizer)
			{
				SetHudTextParams(-1.0, 0.3, 1.20, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
				ShowSyncHudTextToAll(g_Hud_Synchronizer, "%t", "Warmup Hud Timeleft", g_WarmupTimeLeft / 60, g_WarmupTimeLeft % 60);
			}
		}
	}
	
	g_WarmupTimeLeft--;
	return Plugin_Continue;
}

void ShowSyncHudTextToAll(Handle hudSync, const char[] format, any ...)
{
	char buffer[198];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			
			ClearSyncHud(i, hudSync);
			ShowSyncHudText(i, hudSync, buffer);
		}
	}
}
