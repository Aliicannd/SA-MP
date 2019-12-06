#define FILTERSCRIPT
#include <a_samp>

new 	PlayerText:HizBar[MAX_PLAYERS][16],
	PlayerText:HizText[MAX_PLAYERS];
	
new	const L_color[] =
{
	0xffffffff, 0xCBFFBFff, 0xCBFFBFff,
	0x94FF7Dff, 0xB5FE63ff, 0xEBFE63ff,
	0xFFE862ff, 0xFFD362ff, 0xFEB063ff,
	0xFEA043ff, 0xFEA043ff, 0xFE7B43ff,
	0xFE7B43ff, 0xFF0606ff, 0xFF0606ff,
	0xFF0000FF, 0xFF0000FF
};

public OnPlayerConnect(playerid)
{
	HizBar[playerid][0] = CreatePlayerTextDraw(playerid,632.000000, 414.000000, "I");
	HizBar[playerid][1] = CreatePlayerTextDraw(playerid,629.000000, 414.000000, "I");
	HizBar[playerid][2] = CreatePlayerTextDraw(playerid,626.000000, 414.000000, "I");
	HizBar[playerid][3] = CreatePlayerTextDraw(playerid,623.000000, 414.000000, "I");
	HizBar[playerid][4] = CreatePlayerTextDraw(playerid,620.000000, 414.000000, "I");
	HizBar[playerid][5] = CreatePlayerTextDraw(playerid,617.000000, 414.000000, "I");
	HizBar[playerid][6] = CreatePlayerTextDraw(playerid,614.000000, 414.000000, "I");
	HizBar[playerid][7] = CreatePlayerTextDraw(playerid,611.000000, 414.000000, "I");
	HizBar[playerid][8] = CreatePlayerTextDraw(playerid,608.000000, 414.000000, "I");
	HizBar[playerid][9] = CreatePlayerTextDraw(playerid,605.000000, 414.000000, "I");
	HizBar[playerid][10] = CreatePlayerTextDraw(playerid,602.000000, 414.000000, "I");
	HizBar[playerid][11] = CreatePlayerTextDraw(playerid,599.000000, 414.000000, "I");
	HizBar[playerid][12] = CreatePlayerTextDraw(playerid,596.000000, 414.000000, "I");
	HizBar[playerid][13] = CreatePlayerTextDraw(playerid,593.000000, 414.000000, "I");
	HizBar[playerid][14] = CreatePlayerTextDraw(playerid,590.000000, 414.000000, "I");
	HizBar[playerid][15] = CreatePlayerTextDraw(playerid,587.000000, 414.000000, "I");
	for (new i; i != 16; i++)
	{
		PlayerTextDrawAlignment(playerid,HizBar[playerid][i], 2);
		PlayerTextDrawBackgroundColor(playerid,HizBar[playerid][i], 255);
		PlayerTextDrawFont(playerid,HizBar[playerid][i], 1);
		PlayerTextDrawLetterSize(playerid,HizBar[playerid][i], -0.330000, 2.099999);
		PlayerTextDrawColor(playerid,HizBar[playerid][i], 0x66666644);
		PlayerTextDrawSetOutline(playerid,HizBar[playerid][i], 0);
		PlayerTextDrawSetProportional(playerid,HizBar[playerid][i], 1);
		PlayerTextDrawSetShadow(playerid,HizBar[playerid][i], 0);
		PlayerTextDrawSetSelectable(playerid,HizBar[playerid][i], 0);
	}
	HizText[playerid] = CreatePlayerTextDraw(playerid,634.000000, 431.000000, " ");
	PlayerTextDrawAlignment(playerid,HizText[playerid], 3);
	PlayerTextDrawBackgroundColor(playerid,HizText[playerid], 255);
	PlayerTextDrawFont(playerid,HizText[playerid], 2);
	PlayerTextDrawLetterSize(playerid,HizText[playerid], 0.230000, 1.000000);
	PlayerTextDrawColor(playerid,HizText[playerid], -1);
	PlayerTextDrawSetOutline(playerid,HizText[playerid], 0);
	PlayerTextDrawSetProportional(playerid,HizText[playerid], 1);
	PlayerTextDrawSetShadow(playerid,HizText[playerid], 0);
	PlayerTextDrawSetSelectable(playerid,HizText[playerid], 0);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	for (new i = 1; i != 16; i++)
	{
	    PlayerTextDrawHide(playerid, HizBar[playerid][i]);
		PlayerTextDrawDestroy(playerid,HizBar[playerid][i]) ;
	}
 	PlayerTextDrawHide(playerid, HizText[playerid]);
	PlayerTextDrawDestroy(playerid, HizText[playerid]);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		new Float:L_update[4],total_speed, str[24];
		GetVehicleVelocity(GetPlayerVehicleID(playerid), L_update[0], L_update[1], L_update[2]) ;
		L_update[3] = floatsqroot(floatpower(floatabs(L_update[0]), 2.0) + floatpower (floatabs(L_update[1]), 2.0) + floatpower(floatabs(L_update[2]), 2.0)) * 14.0;
		total_speed = floatround(L_update[3]);
		for(new i; i != 16; i++)
		{
			if(i < total_speed)
			{
				PlayerTextDrawColor(playerid,HizBar[playerid][i], L_color[i]);
			}else
			{
				PlayerTextDrawColor(playerid,HizBar[playerid][i], 0x66666644);
			}
			PlayerTextDrawShow(playerid, HizBar[playerid][i]);
		}
		format(str, sizeof(str),"~w~~h~~h~%d",GetVehicleSpeed(GetPlayerVehicleID(playerid)));
		PlayerTextDrawSetString(playerid, HizText[playerid], str);
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
 	{
		for(new i; i != 16; i++)
		{
			PlayerTextDrawColor(playerid, HizBar[playerid][i], 0x66666644);
			PlayerTextDrawShow(playerid, HizBar[playerid][i]);
		}
		PlayerTextDrawShow(playerid, HizText[playerid]);
	}else
	{
		for(new i; i != 16; i++)
		{
			PlayerTextDrawHide(playerid, HizBar[playerid][i]);
		}
		PlayerTextDrawHide(playerid, HizText[playerid]);
	}
	return 1;
}

GetVehicleSpeed(vehicleid)
{
	new Float:Pos[3], Float:ARRAY;
	GetVehicleVelocity(vehicleid, Pos[0], Pos[1], Pos[2]);
	ARRAY = floatsqroot(Pos[0]*Pos[0] + Pos[1]*Pos[1] + Pos[2]*Pos[2])*180;
	return floatround(ARRAY,floatround_round);
}
