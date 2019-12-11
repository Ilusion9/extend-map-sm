#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name = "Extend Map",
	author = "Ilusion9",
	description = "A command where players can request to extend the current map",
	version = "1.1",
	url = "https://github.com/Ilusion9/"
};

ConVar g_Cvar_ExtendTime;
ConVar g_Cvar_MaxExtends;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_PercentageRequired;
ConVar g_Cvar_ExtendCurrentRound;

int g_Votes;
int g_Extends;
bool g_HasVoted[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("extendmap.phrases");

	g_Cvar_ExtendTime = CreateConVar("sm_extendmap_extendtime", "10", "The current map will be extended with this much time.", FCVAR_NONE, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_extendmap_minplayers", "1", "NNumber of players required before the extend command will be enabled.", FCVAR_NONE, true, 1.0);
	g_Cvar_MaxExtends = CreateConVar("sm_extendmap_maxextends", "1", "If set, how many times can be extended the current map?", FCVAR_NONE, true, 0.0);
	g_Cvar_PercentageRequired = CreateConVar("sm_extendmap_percentagereq", "0.60", "Percentage of players required to extend the current map (def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_ExtendCurrentRound = CreateConVar("sm_extendmap_extendcurrentround", "0", "Extend the current round as well? (for deathmatch servers where timelimit = roundtime)", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "extendmap");
	RegConsoleCmd("sm_extend", Command_VoteExtend);
}

public void OnMapStart()
{
	g_Votes = 0;
	g_Extends = 0;
}

public void OnClientConnected(int client)
{
	g_HasVoted[client] = false;
}

public void OnClientDisconnect(int client)
{
	if (g_HasVoted[client])
	{
		g_Votes--;
	}
	
	int players = GetRealClientCount(client);
	if (players >= g_Cvar_MinPlayers.IntValue)
	{
		int requiredVotes = RoundToCeil(players * g_Cvar_PercentageRequired.FloatValue);
		if (g_Votes >= requiredVotes)
		{
			ExtendCurrentMap();
		}
	}
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (StrEqual(sArgs, "extend", false))
	{
		ReplySource oldSource = SetCmdReplySource(SM_REPLY_TO_CHAT);
		AttemptVoteExtend(client);
		SetCmdReplySource(oldSource);
	}
}

public Action Command_VoteExtend(int client, int args)
{
	AttemptVoteExtend(client);
	return Plugin_Handled;
}

void AttemptVoteExtend(int client)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return;
	}
	
	int players = GetRealClientCount();
	if (players < g_Cvar_MinPlayers.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "Min Players To Extend");
		return;			
	}
	
	if (g_Extends >= g_Cvar_MaxExtends.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "Max Extends Reached");
		return;
	}
	
	int requiredVotes = RoundToCeil(players * g_Cvar_PercentageRequired.FloatValue);
	if (g_HasVoted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted for Extend", g_Votes, requiredVotes);
		return;
	}
	
	g_Votes++;
	g_HasVoted[client] = true;
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("[SM] %t", "Vote for Extend Accepted", name, g_Votes, requiredVotes);
	
	if (g_Votes >= requiredVotes)
	{
		ExtendCurrentMap();
	}
}

void ExtendCurrentMap()
{
	PrintToChatAll("[SM] %t", "Current Map Extended", g_Cvar_ExtendTime.IntValue);
	
	ExtendMapTimeLimit(g_Cvar_ExtendTime.IntValue * 60);
	if (g_Cvar_ExtendCurrentRound.BoolValue)
	{
		ExtendRoundTime(g_Cvar_ExtendTime.IntValue * 60);
	}
	
	g_Extends++;
	ResetVotes();
}

void ResetVotes()
{
	g_Votes = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_HasVoted[i] = false;
	}
}

void ExtendRoundTime(int seconds)
{
	GameRules_SetProp("m_iRoundTime", GetRoundTime() + seconds, 4, 0, true); 
}

int GetRoundTime()
{
	return GameRules_GetProp("m_iRoundTime", 4, 0);
}

int GetRealClientCount(int skipClient = 0)
{
	int num = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != skipClient && IsClientInGame(i) && !IsFakeClient(i))
		{
			num++;
		}
	}
	
	return num; 
}
