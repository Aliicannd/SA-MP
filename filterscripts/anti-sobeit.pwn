#define FILTERSCRIPT
#include <a_samp>

new bool:SobSpawn[MAX_PLAYERS] = {false, ...}, 
	 SobVeh[MAX_PLAYERS], 
	 SobTimer[MAX_PLAYERS] = {-1, ...};

public OnPlayerConnect(playerid)
{
	SobSpawn[playerid] = false;
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if(SobTimer[playerid] != -1) KillTimer(SobTimer[playerid]);
	return 1;
}
public OnPlayerSpawn(playerid)
{
    if(SobSpawn[playerid] == false)
    {
		CheckS0beit(playerid);
		return 1;
    }
    return 1;
}
stock CheckS0beit(playerid)
{
	SetPlayerVirtualWorld(playerid, 100+playerid);
	ResetPlayerWeapons(playerid);
	SobVeh[playerid] = CreateVehicle(457, 2109.1763, 1503.0453, 32.2887, 82.2873, 0, 1, 60);
	SetVehicleVirtualWorld(SobVeh[playerid], 100+playerid);
	PutPlayerInVehicle(playerid, SobVeh[playerid], 0);
	RemovePlayerFromVehicle(playerid);
	DestroyVehicle(SobVeh[playerid]);
	SetPlayerPos(playerid, 0.0, 0.0, 10000.0);
	KillTimer(SobTimer[playerid]);
	SobTimer[playerid] = SetTimerEx("AntiS0bek", 1000, false, "i", playerid);
}
forward AntiS0bek(pID);
public AntiS0bek(pID)
{
	new dt[2];
 	GetPlayerWeaponData(pID, WEAPON_GOLFCLUB-1, dt[0], dt[1]);
  	if(dt[0] == WEAPON_GOLFCLUB)
	{
		BanEx(pID, "OROSPU COCUGU!");
	}else
	{
		ResetPlayerWeapons(pID);
  		SobSpawn[pID] = true;
	  	SpawnPlayer(pID);
   	}
	SobTimer[playerid] = -1;
	return 1;
}
