/*
		3D Speedometer by SDraw
		
		Topic: https://forum.sa-mp.com/showthread.php?t=454410
*/

#define FILTERSCRIPT
#include <a_samp>
#include <streamer>

new SpdObj[MAX_PLAYERS][2];
new bool:UpdateSpeed[MAX_PLAYERS] = {false, ...};

public OnPlayerConnect(playerid)
{
	UpdateSpeed[playerid] = false;
	SpdObj[playerid][0] = SpdObj[playerid][1] = INVALID_OBJECT_ID;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(SpdObj[playerid][0] != INVALID_OBJECT_ID)
	{
		DestroyDynamicObject(SpdObj[playerid][0]), DestroyDynamicObject(SpdObj[playerid][1]);
	}
	return 1;
}
public OnPlayerUpdate(playerid)
{
	if(UpdateSpeed[playerid])
	{
		new str[12];
		format(str, sizeof(str), "%.0f KM/H", GetVehicleSpeed(GetPlayerVehicleID(playerid)));
		SetDynamicObjectMaterialText(SpdObj[playerid][0], 0, str, OBJECT_MATERIAL_SIZE_512x256, "Arial", 64, true, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
	}
	return 1;
}

public OnPlayerStateChange(playerid,newstate,oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
	{
		new Float:x, Float:y, Float:z, vehid = GetPlayerVehicleID(playerid);
		SpdObj[playerid][0] = CreateDynamicObject(19482, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1, -1, playerid, 200.0);
		SpdObj[playerid][1] = CreateDynamicObject(19482, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1, -1, playerid, 200.0);
		GetVehicleModelInfo(GetVehicleModel(vehid), VEHICLE_MODEL_INFO_SIZE, x, y, z);
		AttachDynamicObjectToVehicle(SpdObj[playerid][0], vehid, -x-0.5, 0.0, z/2-0.3, 0.0, 0.0, 270.0);
		SetDynamicObjectMaterialText(SpdObj[playerid][1], 0, "_________", OBJECT_MATERIAL_SIZE_512x256, "Arial", 64, true, 0xFF4EFD71, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
		AttachDynamicObjectToVehicle(SpdObj[playerid][1], vehid, -x-0.5, 0.0, z/2-0.3, 0.0, 0.0, 270.0);
		Streamer_Update(playerid);
		UpdateSpeed[playerid] = true;
		return 1;
	}
	if(oldstate == PLAYER_STATE_DRIVER)
	{
		UpdateSpeed[playerid] = false;
		DestroyDynamicObject(SpdObj[playerid][0]);
		DestroyDynamicObject(SpdObj[playerid][1]);
		SpdObj[playerid][0] = INVALID_OBJECT_ID;
		SpdObj[playerid][1] = INVALID_OBJECT_ID;
		return 1;
	}
	return 1;
}

GetVehicleSpeed(vehicleid)
{
	new Float:x, Float:y, Float:z;
	GetVehicleVelocity(vehicleid, x, y, z);
	return floatround(floatsqroot(x*x+y*y+z*z)*200.2);
}
