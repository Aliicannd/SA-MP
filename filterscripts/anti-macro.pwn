#define FILTERSCRIPT
#include <a_samp>

#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

#define ANTIMACRO_MAX_WARNINGS			3
#define ANTIMACRO_MIN_SPEED				40
#define ANTIMACRO_MIN_SPEED_DIFF		0
#define ANTIMACRO_SPRINT_KEY_LIMIT		65
#define ANTIMACRO_FORGET_WARNING_AFTER	900

enum ANTIMACRO_DATA_STRUCTURE
{
	LastTimeSprinted,
	LastMonitoredSpeed,
	TimesWarned,
	LastTimeWarned
}
new AntimacroData[MAX_PLAYERS][ANTIMACRO_DATA_STRUCTURE];
bool:CheckPlayerSprintMacro(playerid, newkeys, oldkeys)
{
	if(PRESSED(KEY_SPRINT))
	{
		new speed = GetPlayerSpeed(playerid);
		new tick = GetTickCount();
		if(GetPlayerVehicleID(playerid) != 0)
		{
			UpdatePlayerSprintMacroData(playerid, speed, tick, true);
			return false;
		}
		if(GetPlayerSurfingVehicleID(playerid) != INVALID_VEHICLE_ID)
		{
			UpdatePlayerSprintMacroData(playerid, speed, tick, true);
			return false;
		}
		if(speed < ANTIMACRO_MIN_SPEED)
		{
			UpdatePlayerSprintMacroData(playerid, speed, tick, true);
			return false;
		}
		if((speed - AntimacroData[playerid][LastMonitoredSpeed]) < ANTIMACRO_MIN_SPEED_DIFF)
		{
			UpdatePlayerSprintMacroData(playerid, speed, tick, true);
			return false;
		}
		new diff = tick - AntimacroData[playerid][LastTimeSprinted];
		if(diff >= ANTIMACRO_SPRINT_KEY_LIMIT || diff == 0)
		{
			UpdatePlayerSprintMacroData(playerid, speed, tick, true);
			return false;
		}
		AntimacroData[playerid][TimesWarned] ++;
		AntimacroData[playerid][LastTimeWarned] = tick;
		if(AntimacroData[playerid][TimesWarned] == ANTIMACRO_MAX_WARNINGS)
		{
			AntimacroData[playerid][TimesWarned] = 0;
			AntimacroData[playerid][LastTimeWarned] = 0;
			new str[128], name[24];
			GetPlayerName(playerid, name, 24);
			format(str, sizeof str, "Macro basma orospu çocuğu (%s)", name);
			SendClientMessageToAll(0xFF0000FF, str);
			TogglePlayerControllable(playerid, false);
			TogglePlayerControllable(playerid, true);
			return true;
		}
		UpdatePlayerSprintMacroData(playerid, speed, tick, false);
	}
	return false;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(CheckPlayerSprintMacro(playerid, newkeys, oldkeys) == true) return 1;
	return true;
}
UpdatePlayerSprintMacroData(playerid, speed, tickcount, bool:forget)
{
	AntimacroData[playerid][LastTimeSprinted] = tickcount;
	AntimacroData[playerid][LastMonitoredSpeed] = speed;
	if(forget && AntimacroData[playerid][TimesWarned] > 0)
	{
		if((tickcount - AntimacroData[playerid][LastTimeWarned]) >= (ANTIMACRO_FORGET_WARNING_AFTER - GetPlayerPing(playerid)))
			AntimacroData[playerid][TimesWarned] = 0;
	}
	return true;
}
stock GetPlayerSpeed(playerid)
{
    new Float:velocity[4];
    GetPlayerVelocity(playerid,velocity[0],velocity[1],velocity[2]);
    velocity[3] = floatsqroot(floatpower(floatabs(velocity[0]), 2.0) + floatpower(floatabs(velocity[1]), 2.0) + floatpower(floatabs(velocity[2]), 2.0)) * 179.28625;
    return floatround(velocity[3]);
}
