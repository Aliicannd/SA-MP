#define FILTERSCRIPT
#include <a_samp>
#include <streamer>

#define MAX_PROTECTED_ZONE 5

new	ProtectedZone[MAX_PROTECTED_ZONE],
	Text3D:ProtectedZoneLabel[MAX_PROTECTED_ZONE];

enum pzonedata
{
	Float:pzPos[3],
	pzDistance
}
new PZones[MAX_PROTECTED_ZONE][pzonedata] =
{
	{{1639.2581, 1519.5576, 14.2100}, 40},
	{{1519.8152, -1458.3143, 9.5125}, 40},
	{{959.0981, 2404.8867, 21.0774}, 40},
	{{-2135.6199, -2375.9426, 32.0259}, 40},
	{{-2767.2407, 1343.8046, 24.2535}, 40}
};
public OnFilterScriptInit()
{
	for(new i = 0; i < sizeof(PZones); i++)
	{
		ProtectedZone[i] = CreateDynamicSphere(PZones[i][pzPos][0], PZones[i][pzPos][1], PZones[i][pzPos][2], PZones[i][pzDistance]);
		ProtectedZoneLabel[i] = Create3DTextLabel("Protected Zone", 0xFF0000FF, PZones[i][pzPos][0], PZones[i][pzPos][1], PZones[i][pzPos][2], 100.0, 0, 1);
	}
	return 1;
}
public OnFilterScriptExit()
{
	for(new i = 0; i < sizeof(PZones); i++)
	{
		Delete3DTextLabel(ProtectedZoneLabel[i]);
	}
	return 1;
}
public OnPlayerEnterDynamicArea(playerid, areaid)
{
	for(new i = 0; i < sizeof(PZones); i++)
	{
		if(areaid == ProtectedZone[i])
		{
			if(IsPlayerInAnyVehicle(playerid))
			{
				new Float:sPos[3];
				GetVehicleVelocity(GetPlayerVehicleID(playerid), sPos[0], sPos[1], sPos[2]);
				SetVehicleVelocity(GetPlayerVehicleID(playerid), sPos[0], sPos[1]-10, sPos[2]);
			}
		}
	}
	return 1;
}
