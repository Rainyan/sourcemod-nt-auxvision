#include <sourcemod>

#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1.0"

#define DEBUG_PROFILE 0
#if DEBUG_PROFILE
#include <profiler>
Profiler _prof;
#endif

ConVar _aux_secs, _cooldown, _init_cost;

public Plugin myinfo = {
	name = "NT vision modes AUX cost",
	description = "Makes vision modes use AUX power",
	author = "Rain",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rainyan/sourcemod-nt-auxvision"
};

public void OnPluginStart()
{
#if DEBUG_PROFILE
	_prof = new Profiler();
#endif

	_aux_secs = CreateConVar("sm_auxvision_lenght_secs", "8.0",
		"How long the vision mode can be kept on at full AUX level",
		_, true, 0.001);
	_cooldown = CreateConVar("sm_auxvision_cooldown_secs", "4.0",
		"How long can the vision mode not be enabled after exhausting it",
		_, true, 0.0);
	_init_cost = CreateConVar("sm_auxvision_initial_cost", "4.0",
		"How much AUX does starting the vision mode cost",
		_, true, 0.0, true, 100.0);

	AutoExecConfig();
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3],
	float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount,
	int& seed, int mouse[2])
{
#if DEBUG_PROFILE
	_prof.Start();
#endif

	static bool prev_vision[NEO_MAXPLAYERS + 1];

	float aux = GetPlayerAUX(client);

	if (!IsPlayerAlive(client) || !IsUsingVision(client))
	{
		if (aux <= _init_cost.FloatValue)
		{
			buttons &= ~IN_VISION;
		}
		prev_vision[client] = false;

#if DEBUG_PROFILE
		_prof.Stop();
		PrintToServer("OnPlayerRunCmd: %f", _prof.Time);
#endif
		return Plugin_Continue;
	}

	if (!prev_vision[client])
	{
		prev_vision[client] = true;
		aux -= _init_cost.FloatValue;
	}

	if (RoundToFloor(aux) <= 0)
	{
		buttons &= ~IN_VISION;
		SetPlayerVision(client, 0);
		SetPlayerAUX(client,
			-_cooldown.FloatValue * GetAUXRecoveryScale(GetPlayerClass(client))
		);
#if DEBUG_PROFILE
		_prof.Stop();
		PrintToServer("OnPlayerRunCmd: %f", _prof.Time);
#endif
		return Plugin_Continue;
	}

	// TODO: refactor
	aux -= 10.0 * (10.0 / _aux_secs.FloatValue) * GetAUXDrainScale(GetPlayerClass(client));

	SetPlayerAUX(client, aux);

#if DEBUG_PROFILE
	_prof.Stop();
	PrintToServer("OnPlayerRunCmd: %f", _prof.Time);
#endif
	return Plugin_Continue;
}

float GetAUXDrainScale(int class)
{
	// TODO: there's probably a simpler way to express this
	float a = 0.32 * GetAUXRecoveryScale(class);
	float scale = 80.0 / a;
	return scale * a * Pow(GetTickInterval(), 2.0);
}

float GetAUXRecoveryScale(int class)
{
	switch (class)
	{
		case CLASS_RECON: return 5.0;
		case CLASS_ASSAULT: return 2.5;
	}
	return 0.0;
}