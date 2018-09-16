#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>
#include <foreach>

new GunGameWeapons[14] =//http://weedarr.wikidot.com/gunlist
{
	23,//Silenced pistol
	22,//9mm Pistol
	27,//Combat shotgun
	26,//Sawn-off shotgun
	29,//Mp5
	32,//Tec 9
	30,//Ak47
	31,//M4
	24,//Desert eagle
	33,//Country rifle
	34,//Sniper rifle
	35,//Rpg
	36,//Heat seeking rocket
	38//Mini gun
};
new GunGameLevel[MAX_PLAYERS];
new PlayerText:GungameTextdraw[MAX_PLAYERS];
new Iterator:GunGamePlayers<MAX_PLAYERS>;

#define GUNGAME_PRICE 2000 // GunGame ödülü

public OnFilterScriptInit()
{
	print("Excision's GunGame System Loaded");
	return 1;
}

public OnPlayerConnect(playerid)
{
	GunGameLevel[playerid] = 0;

	GungameTextdraw[playerid] = CreatePlayerTextDraw(playerid, 514.799987, 275.866699, " ");
	PlayerTextDrawLetterSize(playerid, GungameTextdraw[playerid],  0.280000, 1.000000);
	PlayerTextDrawAlignment(playerid, GungameTextdraw[playerid], 1);
	PlayerTextDrawColor(playerid, GungameTextdraw[playerid], -1);
	PlayerTextDrawSetShadow(playerid, GungameTextdraw[playerid], 1);
	PlayerTextDrawSetOutline(playerid, GungameTextdraw[playerid], 1);
	PlayerTextDrawFont(playerid, GungameTextdraw[playerid], 1);
	PlayerTextDrawSetProportional(playerid, GungameTextdraw[playerid], 1);
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID && Iter_Contains(GunGamePlayers, playerid) && Iter_Contains(GunGamePlayers, killerid))
	{
		GunGameLevel[killerid]++;
		ResetPlayerWeapons(killerid);
		if(GunGameLevel[killerid] == 14)
		{
			new str[144], isim[24];
			GetPlayerName(killerid, isim, 24);
			format(str, sizeof(str), "GunGame i %s isimli oyuncu kazandı!", isim);
			SendClientMessageToAll(0xA60BDDFF, str);
			GivePlayerMoney(killerid, GUNGAME_PRICE);
			foreach(new i: GunGamePlayers)
			{
				GunGameLevel[i] = 0;
				LeaveFromGunGame(i);
				GameTextForPlayer(i, "~r~GunGame Bitti!.", 3500, 3);
			}
		}else GivePlayerWeapon(killerid, GunGameWeapons[GunGameLevel[killerid]], 9999);
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
	if(Iter_Contains(GunGamePlayers, playerid))
	{
		ResetPlayerWeapons(playerid);
		SpawnInGunGame(playerid);
		return 1;
	}
	return 1;
}
forward OnPlayerUpdate(playerid);
public OnPlayerUpdate(playerid)
{
	if(Iter_Contains(GunGamePlayers, playerid))
	{
		new str[126], silah[24];
		GetWeaponName(GetPlayerWeapon(playerid), silah, 24);
		format(str, sizeof(str), "~b~Silah: ~w~%s~n~~b~Level: ~w~%d~n~~b~", silah, GunGameLevel[playerid]);
		PlayerTextDrawSetString(playerid, GungameTextdraw[playerid], str);
	}
	return 1;
}
CMD:gungame(playerid)
{
	if(Iter_Contains(GunGamePlayers, playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Zaten gungamedesiniz. Çıkmak için /gayril yazin.");
	Iter_Add(GunGamePlayers, playerid);
	GunGameLevel[playerid] = 0;
	SpawnInGunGame(playerid);
	PlayerTextDrawShow(playerid, GungameTextdraw[playerid]);
	return 1;
}
CMD:gayril(playerid)
{
	if(!Iter_Contains(GunGamePlayers, playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Zaten gungamede değilsiniz. Katılmak için /gungame yazin.");
	SendClientMessage(playerid, 0xA60BDDFF, "Gungameden ayrıldınız");
	LeaveFromGunGame(playerid);
	return 1;
}
stock LeaveFromGunGame(playerid)
{
	if(Iter_Contains(GunGamePlayers, playerid))
	{
		Iter_Remove(GunGamePlayers, playerid);
		GunGameLevel[playerid] = 0;
		SetPlayerVirtualWorld(playerid, 0);
		ResetPlayerWeapons(playerid);
		SpawnPlayer(playerid);
		PlayerTextDrawHide(playerid, GungameTextdraw[playerid]);
	}
	return 1;
}
stock SpawnInGunGame(playerid)
{
	SetPlayerInterior(playerid, 10);
	SetPlayerVirtualWorld(playerid, 95);
	switch(random(5))
	{
		case 0: SetPlayerPos(playerid, -975.1050, 1061.5844, 1345.6755);
		case 1: SetPlayerPos(playerid, -1042.6305, 1031.9932, 1342.7920);
		case 2: SetPlayerPos(playerid, -1089.8619, 1094.6024, 1343.4906);
		case 3: SetPlayerPos(playerid, -1130.3995, 1057.9498, 1346.4141);
		case 4: SetPlayerPos(playerid, -1078.9012, 1020.9278, 1342.7163);
	}
	ResetPlayerWeapons(playerid);
	GivePlayerWeapon(playerid, GunGameWeapons[GunGameLevel[playerid]], 99999);
	SetPlayerHealth(playerid, 100), SetPlayerArmour(playerid, 100);
	return 1;
}
