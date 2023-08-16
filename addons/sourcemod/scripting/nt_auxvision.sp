#include <sourcemod>

#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.2.0"

#define DEBUG_PROFILE 0
#if DEBUG_PROFILE
#include <profiler>
Profiler _prof;
#endif

#define BF_RECON (1 << 0)
#define BF_ASSAULT (1 << 1)
#define BF_SUPPORT (1 << 2)
// Which class(es) to have AUX cost enabled for, by default.
#define DEFAULT_CLASS_BITS (BF_ASSAULT)
#define MAX_CLASS_BITS (BF_RECON | BF_ASSAULT | BF_SUPPORT)

ConVar _aux_secs, _cooldown, _init_cost, _class_bits;

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

	char bits_buffer[4];
	IntToString(DEFAULT_CLASS_BITS, bits_buffer, sizeof(bits_buffer));
	_class_bits = CreateConVar("sm_auxvision_class_bits", bits_buffer,
		"Bit flags for which classes to enable AUX cost for. Recon: 1, Assault: 2, Support: 4. Note that since supports have no AUX, enabling vision AUX cost for them will do nothing.",
		_, true, 0.0, true, float(MAX_CLASS_BITS));

	AutoExecConfig();
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3],
	float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount,
	int& seed, int mouse[2])
{
#if DEBUG_PROFILE
	_prof.Start();
#endif

	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int class = GetPlayerClass(client);

	if (!(GetBitsOfClass(class) & _class_bits.IntValue))
	{
		return Plugin_Continue;
	}

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
		SetPlayerAUX(client, -_cooldown.FloatValue * GetAUXRecoveryScale(class));
#if DEBUG_PROFILE
		_prof.Stop();
		PrintToServer("OnPlayerRunCmd: %f", _prof.Time);
#endif
		return Plugin_Continue;
	}

	// TODO: refactor
	aux -= 10.0 * (10.0 / _aux_secs.FloatValue) *
		GetAUXDrainScale(class) *
		80.0 * Pow(GetTickInterval(), 2.0);

	SetPlayerAUX(client, aux);

#if DEBUG_PROFILE
	_prof.Stop();
	PrintToServer("OnPlayerRunCmd: %f", _prof.Time);
#endif
	return Plugin_Continue;
}

int GetBitsOfClass(int class)
{
	if (class == CLASS_RECON)
	{
		return BF_RECON;
	}
	if (class == CLASS_ASSAULT)
	{
		return BF_ASSAULT;
	}
	if (class == CLASS_SUPPORT)
	{
		return BF_SUPPORT;
	}
	return 0;
}

float GetAUXDrainScale(int class)
{
	if (class == CLASS_RECON)
	{
		return 1.25;
	}
	if (class == CLASS_ASSAULT)
	{
		return 1.0;
	}
	return 0.0;
}

float GetAUXRecoveryScale(int class)
{
	if (class == CLASS_RECON)
	{
		return 5.0;
	}
	if (class == CLASS_ASSAULT)
	{
		return 2.5;
	}
	return 0.0;
}