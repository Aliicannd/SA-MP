#define FILTERSCRIPT
#include <a_samp>

new PlayerText:L_draw[MAX_PLAYERS][16];

new const L_color[] =
{
	0xffffffff, 0xCBFFBFff, 0xCBFFBFff,
	0x94FF7Dff, 0xB5FE63ff, 0xEBFE63ff,
	0xFFE862ff, 0xFFD362ff, 0xFEB063ff,
	0xFEA043ff, 0xFEA043ff, 0xFE7B43ff,
	0xFE7B43ff, 0xFF0606ff, 0xFF0606ff,
	0xFF0000FF
};

public OnPlayerConnect(playerid)
{
    L_draw[playerid][0] = CreatePlayerTextDraw(playerid,45.00, 410.00, "");
    L_draw[playerid][1] = CreatePlayerTextDraw(playerid,45.00, 410.00, "10");
    L_draw[playerid][2] = CreatePlayerTextDraw(playerid,32.00, 399.00, "20");
    L_draw[playerid][3] = CreatePlayerTextDraw(playerid,25.00, 384.00, "40");
    L_draw[playerid][4] = CreatePlayerTextDraw(playerid,25.00, 368.00, "60");
    L_draw[playerid][5] = CreatePlayerTextDraw(playerid,31.00, 352.00, "80");
    L_draw[playerid][6] = CreatePlayerTextDraw(playerid,42.00, 338.00, "100");
    L_draw[playerid][7] = CreatePlayerTextDraw(playerid,62.00, 331.00, "120");
    L_draw[playerid][8] = CreatePlayerTextDraw(playerid,79.00, 330.00, "140");
    L_draw[playerid][9] = CreatePlayerTextDraw(playerid,98.00, 331.00, "160");
    L_draw[playerid][10] = CreatePlayerTextDraw(playerid,116.00, 338.00, "180");
    L_draw[playerid][11] = CreatePlayerTextDraw(playerid,130.00, 352.00, "200");
    L_draw[playerid][12] = CreatePlayerTextDraw(playerid,136.00, 368.00, "220");
    L_draw[playerid][13] = CreatePlayerTextDraw(playerid,136.00, 384.00, "240");
    L_draw[playerid][14] = CreatePlayerTextDraw(playerid,130.00, 399.00, "260");
    L_draw[playerid][15] = CreatePlayerTextDraw(playerid,117.00, 410.00, "280");
    for (new i; i != 16; i++)
    {
		PlayerTextDrawBackgroundColor(playerid, L_draw[playerid][i], 0x00000033);
		PlayerTextDrawFont(playerid,L_draw[playerid][i], 2);
		PlayerTextDrawLetterSize(playerid,L_draw[playerid][i], 0.240, 1.300);
		PlayerTextDrawColor(playerid,L_draw[playerid][i], 0x66666644);
		PlayerTextDrawSetOutline(playerid,L_draw[playerid][i], false);
		PlayerTextDrawSetProportional(playerid,L_draw[playerid][i], true);
		PlayerTextDrawSetShadow(playerid,L_draw[playerid][i], false);
	}
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	for (new i = 1; i != 16; i++)
	{
		PlayerTextDrawHide(playerid, L_draw[playerid][i]);
		PlayerTextDrawDestroy(playerid,L_draw[playerid][i]) ;
	}
	return 1;
}
public OnPlayerUpdate(playerid)
{
	if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		new Float:L_update[4],total_speed;
		GetVehicleVelocity(GetPlayerVehicleID(playerid), L_update[0], L_update[1], L_update[2]) ;
		L_update[3] = floatsqroot(floatpower(floatabs(L_update[0]), 2.0) + floatpower (floatabs(L_update[1]), 2.0) + floatpower(floatabs(L_update[2]), 2.0)) * 10.0;
		total_speed = floatround(L_update[3]);
		for(new i; i != 16; i++)
		{
			if(i < total_speed)
			{
				PlayerTextDrawColor(playerid, L_draw[playerid][i], L_color[i]);
			}else
			{
				PlayerTextDrawColor(playerid, L_draw[playerid][i], 0x66666644);
			}
			PlayerTextDrawShow(playerid, L_draw[playerid][i]);
		}
	}
	return 1;
}
public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
 	{
		for(new i; i != 16; i++)
		{
			PlayerTextDrawColor(playerid, L_draw[playerid][i], 0x66666644);
			PlayerTextDrawShow(playerid, L_draw[playerid][i]);
		}
	}else
	{
		for(new i; i != 16; i++)
		{
			PlayerTextDrawHide(playerid, L_draw[playerid][i]);
		}
	}
	return 1;
}
