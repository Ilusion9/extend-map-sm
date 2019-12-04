#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name = "Vote For Map Extend",
	author = "Ilusion9",
	description = "A vote command where players can request to extend the current map",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

ConVar g_Cvar_ExtendTime;
ConVar g_Cvar_MaxExtends;
ConVar g_Cvar_ExtendDelay;
ConVar g_Cvar_ExtendCurrentRound;

int g_Extends;
float g_VoteTime;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("voteformapextend.phrases");

	g_Cvar_ExtendTime = CreateConVar("sm_cmd_extend_time", "10", "The current map will be extended with this much time.", FCVAR_NONE, true, 1.0);
	g_Cvar_MaxExtends = CreateConVar("sm_cmd_extend_limit", "1", "If set, how many times can be extended the current map?", FCVAR_NONE, true, 0.0);
	g_Cvar_ExtendDelay = CreateConVar("sm_cmd_extend_delay", "10", "After how many minutes players can request to extend the map again?", FCVAR_NONE, true, 0.0);
	g_Cvar_ExtendCurrentRound = CreateConVar("sm_cmd_extend_current_round", "0", "Extend the current round as well? (for deathmatch servers where timelimit = roundtime)", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "voteformapextend");
	RegConsoleCmd("sm_ve", Command_VoteExtend);
}

public void OnMapStart()
{
	g_Extends = 0;
	g_VoteTime = 0.0;
}

public Action Command_VoteExtend(int client, int args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
	
	if (g_Extends >= g_Cvar_MaxExtends.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "Extend Vote Limit");
		return Plugin_Handled;
	}
	
	if (g_VoteTime > 0.0)
	{
		float timeLeft = g_VoteTime + g_Cvar_ExtendDelay.FloatValue * 60.0 - GetGameTime();
		
		if (timeLeft > 0.0)
		{
			ReplyToCommand(client, "[SM] %t", "Extend Vote Delay", RoundToZero(timeLeft));
			return Plugin_Handled;
		}
	}
	
	Menu menu = new Menu(MenuHandler_ExtendMapTime, MENU_ACTIONS_ALL);
	menu.VoteResultCallback = VoteResultCallback_ExtendMapTime;
	
	menu.SetTitle("Extend Vote Question");
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	
	menu.ExitButton = false;
	menu.DisplayVoteToAll(15);
	
	return Plugin_Handled;
}

public int MenuHandler_ExtendMapTime(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Display)
	{
		char title[64];
		menu.GetTitle(title, sizeof(title));
		
		char buffer[255];
		Format(buffer, sizeof(buffer), "%T", title, param1, g_Cvar_ExtendTime.IntValue);

		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
	}
	
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
		char buffer[255];
		Format(buffer, sizeof(buffer), "%T", display, param1);

		return RedrawMenuItem(buffer);
	}
	
	return 0;
}

public void VoteResultCallback_ExtendMapTime(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	char display[64];
	menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], "", 0, _, display, sizeof(display));
	
	g_VoteTime = GetGameTime();
	int percent = RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100);
	
	if (StrEqual(display, "Yes", true))
	{
		g_Extends++;
		ExtendMapTimeLimit(g_Cvar_ExtendTime.IntValue * 60);
		
		if (g_Cvar_ExtendCurrentRound.BoolValue)
		{
			ExtendRoundTime(g_Cvar_ExtendTime.IntValue * 60);
		}
		
		PrintToChatAll("[SM] %t", "Extend Vote Successful", percent, num_votes);
	}
	else
	{
		PrintToChatAll("[SM] %t", "Extend Vote Failed", percent, num_votes);
	}
}

int GetRoundTime()
{
	return GameRules_GetProp("m_iRoundTime", 4, 0);
}

void ExtendRoundTime(int seconds)
{
	GameRules_SetProp("m_iRoundTime", GetRoundTime() + seconds, 4, 0, true); 
}
