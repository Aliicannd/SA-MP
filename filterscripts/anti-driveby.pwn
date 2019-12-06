#define FILTERSCRIPT
#include <a_samp>
#include <foreach>

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_PASSENGER && !DriverCheck(GetPlayerVehicleID(playerid)))
	{
		GameTextForPlayer(playerid, "~r~~h~~h~Drive by yasaktir!", 3000, 3);
		SetPlayerArmedWeapon(playerid, 0);
	}
	return 1;
}
DriverCheck(vehicleid)
{
	foreach(new i: Player)
	{
		if(GetPlayerState(i) == PLAYER_STATE_DRIVER && GetPlayerVehicleID(i) == vehicleid) return 1;
	}
	return 0;
}
