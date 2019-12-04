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
ConVar g_Cvar_VotesRequired;
ConVar g_Cvar_ExtendCurrentRound;

int g_Votes;
int g_Extends;
bool g_HasVoted[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("voteformapextend.phrases");

	g_Cvar_ExtendTime = CreateConVar("sm_ve_time", "10", "The current map will be extended with this much time.", FCVAR_NONE, true, 1.0);
	g_Cvar_MaxExtends = CreateConVar("sm_ve_max_extends", "1", "If set, how many times can be extended the current map?", FCVAR_NONE, true, 0.0);
	g_Cvar_VotesRequired = CreateConVar("sm_ve_required", "0.60", "Percentage of players required to extend the current map (def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_ExtendCurrentRound = CreateConVar("sm_ve_current_round", "0", "Extend the current round as well? (for deathmatch servers where timelimit = roundtime)", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "voteformapextend");
	RegConsoleCmd("sm_ve", Command_VoteExtend);
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
	
	int requiredVotes = RoundToCeil(GetRealClientCount(client) * g_Cvar_VotesRequired.FloatValue);
	if (g_Votes >= requiredVotes)
	{
		ExtendCurrentMap();
	}
}

public Action Command_VoteExtend(int client, int args)
{
	if (g_Extends >= g_Cvar_MaxExtends.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "VE Extends Limit");
		return Plugin_Handled;
	}
	
	int requiredVotes = RoundToCeil(GetRealClientCount() * g_Cvar_VotesRequired.FloatValue);
	if (g_HasVoted[client])
	{
		ReplyToCommand(client, "[SM] %t", "VE Already Voted", g_Votes, requiredVotes);
		return Plugin_Handled;
	}
	
	g_Votes++;
	g_HasVoted[client] = true;
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("[SM] %t", "VE Requested", name, g_Votes, requiredVotes);
	
	if (g_Votes >= requiredVotes)
	{
		ExtendCurrentMap();
	}
	
	return Plugin_Handled;
}

void ExtendCurrentMap()
{
	PrintToChatAll("[SM] %t", "VE Map Extended", g_Cvar_ExtendTime.IntValue);
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
