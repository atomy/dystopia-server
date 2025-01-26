/*
* dys_roundstart
*
* what it does (timeline):
* - starts a warmup phase at beginning of the map
* - waits for time to run out (dys_warmuptime) or if both of the teams get the number of players specified in (dys_startplayers) CVAR
*  - so if one condition is done the round will start
* - roundstart will be 1 restarts, for keeping the teams in same position (defending/attacking)
* - if map_restart is triggered dys_roundstart will be set to 0 and to 1 again, no warmup
*
* what u need:
* - just sourcemod
*
* how to config / useful cvars:
* - dys_warmuptime -> how long the warmup phase take (0 = disable warmup)
* - dys_startplayers -> minimum players on both teams to start a round before dys_warmuptime rans out (0 = disable it, warmuptime only)
* - dys_gamestarted -> represents the game state, for further usage in other plugins
*
* additional notes:
* - that plugin can be linked with dys_spawnteam which provides instant spawn during warmup, if dont want this (until u are using both of the plugins)
*   comment those lines out "SetConVarInt(CVAR_dys_instant_spawn, 1, false, false)" -> //SetConVarInt(CVAR_dys_instant_spawn, 1, false, false)
*/

#define PLUGIN_VERSION "1.0.0"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new startdelaytimer = 0

new Handle:timer_cd = INVALID_HANDLE
new Handle:CVAR_dys_gamestarted = INVALID_HANDLE
new Handle:CVAR_dys_warmuptime = INVALID_HANDLE
new Handle:CVAR_dys_warmup = INVALID_HANDLE
new Handle:CVAR_dys_startplayers = INVALID_HANDLE
new Handle:CVAR_dys_instant_spawn = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "dys_roundstart",
	author = "atomy",
	description = "this plugin provides a warmup phase where all players respawn instantly to have a less boring waiting-for-players-phase",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
}

public OnAllPluginsLoaded()
{
	RegCVARS()
}

public OnMapStart()
{
	CreateTimer(3.0, DelayWarmup)
}

public Action:DelayWarmup(Handle:timer)
{
	Warmup()

	return Plugin_Continue
}

public OnMapEnd()
{
	if (GetConVarInt(CVAR_dys_warmup) == 1)
	{
		KillTimer(timer_cd)
	}
}

public OnPluginEnd()
{
}

public RegCVARS()
{
    CreateConVar("dys_roundstart_version", PLUGIN_VERSION, "The version of 'dys_roundstart' running.",FCVAR_NOTIFY)
	CVAR_mp_instantspawn = FindConVar("mp_instantspawn")
	CVAR_dys_gamestarted = CreateConVar("dys_gamestarted", "0", "cvar indicates state of the game", FCVAR_NOTIFY)
	CVAR_dys_warmuptime = CreateConVar("dys_warmuptime", "0", "sets the warmup time after a game starts", FCVAR_NOTIFY)
	CVAR_dys_warmup = CreateConVar("dys_warmup", "0", "represents the warmup state, if 1 we are in warmup mode", FCVAR_NOTIFY)
	CVAR_dys_startplayers = CreateConVar("dys_startplayers", "0", "represents the minimum number of players on each team, that is needed to cancel the warmup and start the round before warmup ends", FCVAR_NOTIFY)
}

/*
* start teh warmup, the timer
*/
public Warmup()
{
	startdelaytimer = 0
	SetConVarInt(CVAR_dys_gamestarted, 0, false, false)

	if (CVAR_mp_instantspawn)
		SetConVarInt(CVAR_mp_instantspawn, 1, false, false)

	/*
	* we have a warmuptime, countdown to 0
	*/
	if (GetConVarInt(CVAR_dys_warmuptime) > 0)
	{
		SetConVarInt(CVAR_dys_warmup, 1, false, false)
		timer_cd = CreateTimer(1.0, CountdownTimer, _, TIMER_REPEAT)
	}
	else
	{
		LogError("ZOMG dys_warmup is 0")
		SetConVarInt(CVAR_dys_warmup, 0, false, false)
	}
}

/*
* end teh warmup, restarts etc.
*/
public EndWarmup()
{	
	if (CVAR_mp_instantspawn)
		SetConVarInt(CVAR_mp_instantspawn, 0, false, false)
	
	ServerCommand("map_restart")
	CreateTimer(5.0, DelayCvar)
}

public Action:DelayCvar(Handle:timer)
{
	SetConVarInt(CVAR_dys_gamestarted, 1, false, false)
}

/*
* our coutdowntimer, countdown or wait for players, whatever is first
*/
public Action:CountdownTimer(Handle:timer)
{
	new startplayers = GetConVarInt(CVAR_dys_startplayers)
	
	/*
	* timer ran out, start round
	*/
	if (startdelaytimer > GetConVarInt(CVAR_dys_warmuptime))
	{
		SetConVarInt(CVAR_dys_warmup, 0, false, false)
		PrintCenterTextAll("Warmup end!")
		EndWarmup()

		// stop the timer	
		return Plugin_Stop;
	}

	/*
	* if startplayers is set, watch for x players on each team
	*/
	else if (startplayers > 0)
	{
		new ti_punks = FindTeamByName("Punks")
		new ti_corps = FindTeamByName("Corps")
		
		if (ti_punks >= 0 && ti_corps >= 0)
		{
			if (GetTeamClientCount(ti_punks) >= startplayers && GetTeamClientCount(ti_corps) >= startplayers)
			{
	                       	SetConVarInt(CVAR_dys_warmup, 0, false, false)
        	               	PrintCenterTextAll("Warmup end! %i players on each team reached", startplayers)
				EndWarmup()

				// stop the timer
				return Plugin_Stop;
			}
			else
			{
                        	PrintCenterTextAll("Warmup! %is left / waiting for %i players on each team", GetConVarInt(CVAR_dys_warmuptime)-startdelaytimer, startplayers)
                        	startdelaytimer++
			}				
		}
	}
	else
	{
		PrintCenterTextAll("Warmup! %is left", GetConVarInt(CVAR_dys_warmuptime)-startdelaytimer)
		startdelaytimer++
	}
	
	return Plugin_Continue
}
