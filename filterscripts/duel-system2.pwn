#define FILTERSCRIPT
#include <a_samp>
#include <zcmd>
#include <foreach>
#include <sscanf2>

enum
{
    DIALOG_DUEL_WEAP1,
    DIALOG_DUEL_WEAP2,
    DIALOG_DUEL_WEAP3,
    DIALOG_DUEL_ROUND,
    DIALOG_DUEL_PLACE
};
enum Duel
{
	bool: InDuel,
	DuelID,
	WeaponOne,
	WeaponTwo,
	WeaponThree,
	Rounds,
	TotalRounds,
	Float:DuelPos_X,
    	Float:DuelPos_Y,
    	Float:DuelPos_Z,
	RoundsWon,
	Timer,
	World
};
new DuelInfo[MAX_PLAYERS][Duel];

enum WInfo
{
	WeaponName[56],
	WeaponID
};
new Weapon[][WInfo] =
{
	{"Fist", 0},
	{"Brass Knuckle", 1},
	{"Golf Club", 2},
	{"Nigtstick", 3},
	{"Knife", 4},
	{"Baseball Bat", 5},
	{"Shovel", 6},
	{"Pool Cue", 7},
	{"Katana", 8},
	{"Chainsaw", 9},
	{"Purple Dildo", 10},
	{"Dildo", 11},
	{"Vibrator", 12},
	{"Silver Vibrator", 13},
	{"Flowers", 14},
	{"Cane", 15},
	{"Grenade", 16},
	{"Tear Gas", 17},
	{"Molotov Cocktail", 18},
	{"9mm", 22},
	{"Silenced 9mm", 23},
	{"Desert Eagle", 24},
	{"Shotgun", 25},
	{"Sawnoff Shotgun", 26},
	{"Combat Shotgun", 27},
	{"Micro SMG/Uzi", 28},
	{"MP5", 29},
	{"AK-47", 30},
	{"M4", 31},
	{"Tec-9", 32},
	{"Country Rifle", 33},
	{"Sniper Rifle", 34},
	{"RPG", 35},
	{"HS Rocket", 36},
	{"Flametower", 37},
	{"Minigun", 38},
	{"Spraycan", 41},
	{"Fire Extinguisher", 42}
};
public OnPlayerConnect(playerid)
{
	DuelInfo[playerid][DuelID] = -1;
	DuelInfo[playerid][InDuel] = false;
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	DuelInfo[playerid][DuelID] = -1;
	DuelInfo[playerid][InDuel] = false;
	return 1;
}
public OnPlayerSpawn(playerid)
{
	if(DuelInfo[playerid][InDuel] == true)
	{
		if(DuelInfo[playerid][Rounds] >= 1)
		{
			SetDuel(playerid);
			return 1;
		}else if(DuelInfo[playerid][Rounds] == 0)
		{
			ClearDuel(playerid);
		}
	}
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	if(DuelInfo[playerid][InDuel] == true)
	{
		new str[120];
		DuelInfo[killerid][RoundsWon]++;
		DuelInfo[killerid][Rounds]--;
		DuelInfo[playerid][Rounds]--;

		format(str, sizeof(str),"~w~%s(%d)~n~~g~won the round~n~(%d/%d)",GetName(killerid), killerid, DuelInfo[killerid][Rounds], DuelInfo[killerid][TotalRounds]);
		GameTextForPlayer(playerid, str, 6000, 3);
		GameTextForPlayer(killerid, str, 6000, 3);

		if(DuelInfo[killerid][Rounds] == 0)
		{
			new str2[100], winner = -1, loser = -1;
			if(DuelInfo[killerid][RoundsWon] > DuelInfo[playerid][RoundsWon])
			{
				winner = killerid;
				loser = playerid;
			}else if(DuelInfo[playerid][RoundsWon] > DuelInfo[killerid][RoundsWon])
			{
				winner = playerid;
				loser = killerid;
			}
			format(str2, sizeof(str2),"[DUEL] %s(%d) won the duel against %s(%d) [%d:%d]", GetName(winner), winner, GetName(loser), loser, DuelInfo[winner][RoundsWon], DuelInfo[loser][RoundsWon]);
			SendClientMessageToAll(-1, str2);
		}else
		{
			DuelInfo[playerid][InDuel] = true;
			DuelInfo[killerid][InDuel] = true;
			SetDuel(killerid);
		}
	}
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_DUEL_WEAP1)
	{
		if(response)
		{
			new str[50], str2[512];
			DuelInfo[playerid][WeaponOne] = Weapon[listitem][WeaponID];
			for(new i; i < sizeof(Weapon); i++)
		    	{
				format(str,sizeof(str),"%s\n",Weapon[i][WeaponName]);
				strcat(str2, str);
		    	}
		    	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAP2, DIALOG_STYLE_LIST, "Duel Weapon 2", str2, "Next", "Cancel");
		}
	}
	if(dialogid == DIALOG_DUEL_WEAP2)
	{
		if(!response)
		{
			new str[50], str2[512];
			DuelInfo[playerid][WeaponOne] = Weapon[listitem][WeaponID];
			for(new i; i < sizeof(Weapon); i++)
		    	{
				format(str,sizeof(str),"%s\n",Weapon[i][WeaponName]);
				strcat(str2, str);
		    	}
		    	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAP2, DIALOG_STYLE_LIST, "Duel Weapon 2", str2, "Next", "Cancel");
		}else if(response)
		{
			new str[50], str2[512];
			DuelInfo[playerid][WeaponTwo] = Weapon[listitem][WeaponID];
			for(new i; i < sizeof(Weapon); i++)
		    	{
				format(str,sizeof(str),"%s\n",Weapon[i][WeaponName]);
				strcat(str2, str);
		    	}
		    	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAP3, DIALOG_STYLE_LIST, "Duel Weapon 3", str2, "Next", "Back");
		}
	}
	if(dialogid == DIALOG_DUEL_WEAP3)
	{
		if(!response)
		{
			new str[50], str2[512];
			DuelInfo[playerid][WeaponTwo] = Weapon[listitem][WeaponID];
			for(new i; i < sizeof(Weapon); i++)
			{
				format(str,sizeof(str),"%s\n",Weapon[i][WeaponName]);
				strcat(str2, str);
		    	}
		    	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAP3, DIALOG_STYLE_LIST, "Duel Weapon 3", str2, "Next", "Back");
		}else if(response)
		{
			DuelInfo[playerid][WeaponThree] = Weapon[listitem][WeaponID];
			ShowPlayerDialog(playerid, DIALOG_DUEL_ROUND, DIALOG_STYLE_LIST, "Duel Rounds", "1\n2\n3\n4\n5\n6\n7\n8\n9\n10", "Next", "Back");
		}
	}
	if(dialogid == DIALOG_DUEL_ROUND)
	{
		if(!response) ShowPlayerDialog(playerid, DIALOG_DUEL_ROUND, DIALOG_STYLE_LIST, "Duel Rounds", "1\n2\n3\n4\n5\n6\n7\n8\n9\n10", "Next", "Back");
		if(response)
		{
			DuelInfo[playerid][Rounds] = listitem+1;
			DuelInfo[playerid][TotalRounds] = listitem+1;
			ShowPlayerDialog(playerid, DIALOG_DUEL_PLACE, DIALOG_STYLE_LIST, "Duello Place", "{FFFFFF}T 25\nStadium", "Select", "Back");
		}
	}
	if(dialogid == DIALOG_DUEL_PLACE)
	{
		if(response)
		{
			switch(listitem)
			{
				case 0:
				{
					DuelInfo[playerid][DuelPos_X] = 1097.1639;
					DuelInfo[playerid][DuelPos_Y] = 1063.6047;
					DuelInfo[playerid][DuelPos_Z] = 10.8359;
				}
				case 1:
				{
					DuelInfo[playerid][DuelPos_X] = 3374.6348;
					DuelInfo[playerid][DuelPos_Y] = -1734.9648;
					DuelInfo[playerid][DuelPos_Z] = 9.2609;
				}
			}
			new WeapOne[56], WeapTwo[56], WeapThree[56], str[512];

			new id = DuelInfo[playerid][DuelID];
			DuelInfo[id][DuelID] = playerid;
			DuelInfo[id][WeaponOne] = DuelInfo[playerid][WeaponOne];
			DuelInfo[id][WeaponTwo] = DuelInfo[playerid][WeaponTwo];
			DuelInfo[id][WeaponThree] = DuelInfo[playerid][WeaponThree];
			DuelInfo[id][Rounds] = DuelInfo[playerid][Rounds];
			DuelInfo[id][TotalRounds] = DuelInfo[playerid][TotalRounds];
			DuelInfo[id][DuelPos_X] = DuelInfo[playerid][DuelPos_X];
			DuelInfo[id][DuelPos_Y] = DuelInfo[playerid][DuelPos_Y];
			DuelInfo[id][DuelPos_Z] = DuelInfo[playerid][DuelPos_Z];
			DuelInfo[id][World] = DuelInfo[playerid][World] = 1000+playerid;

			GetWeaponName(DuelInfo[playerid][WeaponOne], WeapOne, sizeof(WeapOne));
			GetWeaponName(DuelInfo[playerid][WeaponTwo], WeapTwo, sizeof(WeapTwo));
			GetWeaponName(DuelInfo[playerid][WeaponThree], WeapThree, sizeof(WeapThree));

			format(str, sizeof(str), "[DUEL] %s(%d) has requested a duel with you [Weapons: %s | %s | %s] [Rounds: %d] [Place: %s]", WeapOne, WeapTwo, WeapThree, DuelInfo[playerid][Rounds], ReturnMapName(listitem));
			SendClientMessage(id, -1, str);
			SendClientMessage(id, -1, "[DUEL] Use (/yes) command to accept the duel");
			GameTextForPlayer(playerid,"~g~Duel requested", 4500,3);

			DuelInfo[playerid][Timer] = SetTimerEx("DuelRequestTimer", 30000, false, "i", playerid);
		}
	}
	return 0;
}
stock ReturnMapName(mapid)
{
	new mapstr[56];
	switch(mapid)
	{
	    case 0: mapstr = "T 25";
	    case 1: mapstr = "Stadium";
	}
	return mapstr;
}
CMD:duel(playerid, params[])
{
	new id, str[56], str2[512];
	if(sscanf(params, "u", id)) return GameTextForPlayer(playerid,"~g~/duel~n~~w~(id)",4500,3);
	if(id == INVALID_PLAYER_ID) return GameTextForPlayer(playerid, "~g~Player is not connected", 4500,3);
	if(id == playerid) return GameTextForPlayer(playerid, "~g~Invalid player id", 4500,3);
	DuelInfo[playerid][DuelID] = id;
	for(new i; i < sizeof(Weapon); i++)
	{
		format(str, sizeof(str), "%s\n", Weapon[i][WeaponName]);
		strcat(str2, str);
	}
	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAP1, DIALOG_STYLE_LIST, "Duel Weapon 1", str2, "Next", "Cancel");
	return 1;
}
CMD:yes(playerid)
{
	new str[150], id = DuelInfo[playerid][DuelID];
	if(DuelInfo[playerid][DuelID] == INVALID_PLAYER_ID || DuelInfo[playerid][DuelID] == playerid || DuelInfo[playerid][DuelID] == -1) return GameTextForPlayer(playerid,"~g~Noone requested a duel with you", 4500,3);
	if(!IsPlayerConnected(id)) return GameTextForPlayer(playerid, "~g~Player is not connected", 4500,3);
	SetDuel(playerid);
	SetDuel(id);
	DuelInfo[playerid][InDuel] = true;
	DuelInfo[id][InDuel] = true;
	KillTimer(DuelInfo[id][Timer]);
	format(str, sizeof(str), "~w~%s~n~~g~VS~n~~w~%s~n~~n~%d/%d", GetName(playerid), GetName(id), DuelInfo[playerid][Rounds], DuelInfo[playerid][TotalRounds]);
	GameTextForPlayer(playerid, str, 4500, 3);
	return 1;
}
forward DuelRequestTimer(playerid);
public DuelRequestTimer(playerid)
{
	DuelInfo[playerid][DuelID] = -1;
	DuelInfo[DuelInfo[playerid][DuelID]][DuelID] = -1;
	ClearDuel(playerid);
	return 1;
}
stock ClearDuel(playerid)
{
	DuelInfo[playerid][InDuel] = false;
	DuelInfo[playerid][DuelID] = -1;
	DuelInfo[playerid][Rounds] = 0;
	DuelInfo[playerid][RoundsWon] = 0;
	DuelInfo[playerid][TotalRounds] = 0;
	DuelInfo[playerid][WeaponOne] = -1;
	DuelInfo[playerid][WeaponTwo] = -1;
	DuelInfo[playerid][WeaponThree] = -1;
	DuelInfo[playerid][DuelPos_X] = 0;
	DuelInfo[playerid][DuelPos_Y] = 0;
	DuelInfo[playerid][DuelPos_Z] = 0;
	DuelInfo[playerid][World] = 0;
	return 1;
}
stock SetDuel(playerid)
{
	SetPlayerVirtualWorld(playerid, DuelInfo[playerid][World]);
	ResetPlayerWeapons(playerid);
	SetPlayerPos(playerid, DuelInfo[playerid][DuelPos_X], DuelInfo[playerid][DuelPos_Y], DuelInfo[playerid][DuelPos_Z]);
	GivePlayerWeapon(playerid, DuelInfo[playerid][WeaponOne], 999999);
	GivePlayerWeapon(playerid, DuelInfo[playerid][WeaponTwo], 999999);
	GivePlayerWeapon(playerid, DuelInfo[playerid][WeaponThree], 999999);
	SetPlayerHealth(playerid, 100.0);
	SetPlayerArmour(playerid, 100.0);
	return 1;
}
stock GetName(playerid)
{
	new playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	return playerName;
}
