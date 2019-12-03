#define FILTERSCRIPT
#include <a_samp>
#include <sscanf2>
#include <zcmd>

enum
{
	DIALOG_DUEL_WEAPON = 3254,
	DIALOG_DUEL_WEAPON2,
	DIALOG_DUEL_MAP,
	DIALOG_DUEL
};
enum d_Vars
{
	bool:d_induel,
	d_Rakip,
	d_Weapon,
	d_Weapon2,
	d_Bet,
	d_Map,
	d_Tick
};
new DuelInfo[MAX_PLAYERS][d_Vars];
new Duello_Sayac[MAX_PLAYERS], Duello_Timer[MAX_PLAYERS];

public OnPlayerConnect(playerid)
{
	DuelInfo[playerid][d_induel] = false;
 	DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
	DuelInfo[playerid][d_Weapon] = 0;
	DuelInfo[playerid][d_Weapon2] = 0;
	DuelInfo[playerid][d_Bet] = 0;
	DuelInfo[playerid][d_Map] = 0;
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if(DuelInfo[playerid][d_induel])
	{
	    GivePlayerMoney(DuelInfo[playerid][d_Rakip], DuelInfo[playerid][d_Bet]);
	    GivePlayerMoney(playerid, -DuelInfo[playerid][d_Bet]);
	    new str[144];
	    format(str, sizeof(str), "Duel » {FFFFFF}%s duelloda %s'yı mağlup etti. Silahlar: {FF9900}%s & %s {FFFFFF}Bahis: {FF9900}$%i {FFFFFF}(%s)", PlayerName(DuelInfo[playerid][d_Rakip]), PlayerName(playerid), ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon]),ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon2]), DuelInfo[playerid][d_Bet], ConvertTime(GetTickCount() - DuelInfo[playerid][d_Tick]));
	    SendClientMessageToAll(0x99CC00FF, str);
	    
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel] = false;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Rakip] = INVALID_PLAYER_ID;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon2] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Bet] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Map] = 0;
	    
	    DuelInfo[playerid][d_induel] = false;
	    DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
	    DuelInfo[playerid][d_Weapon] = 0;
	    DuelInfo[playerid][d_Weapon2] = 0;
	    DuelInfo[playerid][d_Bet] = 0;
	    DuelInfo[playerid][d_Map] = 0;
	}
	KillTimer(Duello_Timer[playerid]);
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_DUEL_WEAPON)
	{
	    if(response)
	    {
	        new weaponid;
	        switch(listitem)
		{
				case 0: weaponid = 9;
				case 1: weaponid = 16;
				case 2: weaponid = 18;
				case 3: weaponid = 22;
				case 4: weaponid = 23;
				case 5: weaponid = 24;
				case 6: weaponid = 25;
				case 7: weaponid = 26;
				case 8: weaponid = 27;
				case 9: weaponid = 28;
				case 10: weaponid = 29;
				case 11: weaponid = 30;
				case 12: weaponid = 31;
				case 13: weaponid = 32;
				case 14: weaponid = 33;
				case 15: weaponid = 34;
				default: weaponid = 24;
			}
			DuelInfo[playerid][d_Weapon] = weaponid;
			DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon] = weaponid;

            SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}2. duello silahını seçiniz.");
            new str[512];
            format(str, 512, "{FF0000}» {FFFFFF}Testere\n{FF0000}» {FFFFFF}El Bombası\n{FF0000}» {FFFFFF}Molotof\n{FF0000}» {FFFFFF}9mm\n{FF0000}» {FFFFFF}Silenced\n{FF0000}» {FFFFFF}Deagle\n{FF0000}» {FFFFFF}Shotgun\n{FF0000}» {FFFFFF}Sawn Off\n{FF0000}» {FFFFFF}Combat\n{FF0000}» {FFFFFF}Uzi\n{FF0000}» {FFFFFF}Mp5\n{FF0000}» {FFFFFF}Ak-47\n{FF0000}» {FFFFFF}M4\n{FF0000}» {FFFFFF}Tec-9\n{FF0000}» {FFFFFF}Rifle\n{FF0000}» {FFFFFF}Sniper");
			ShowPlayerDialog(playerid, DIALOG_DUEL_WEAPON2, DIALOG_STYLE_LIST, "{FF0000}LYNX DRIFT - {FFFFFF}Duello Silah 2", str, "Sec", "Iptal");
	    }
	}
	if(dialogid == DIALOG_DUEL_WEAPON2)
	{
	    if(response)
	    {
	        new weaponid;
	        switch(listitem)
			{
				case 0: weaponid = 9;
				case 1: weaponid = 16;
				case 2: weaponid = 18;
				case 3: weaponid = 22;
				case 4: weaponid = 23;
				case 5: weaponid = 24;
				case 6: weaponid = 25;
				case 7: weaponid = 26;
				case 8: weaponid = 27;
				case 9: weaponid = 28;
				case 10: weaponid = 29;
				case 11: weaponid = 30;
				case 12: weaponid = 31;
				case 13: weaponid = 32;
				case 14: weaponid = 33;
				case 15: weaponid = 34;
				default: weaponid = 24;
			}
			DuelInfo[playerid][d_Weapon2] = weaponid;
			DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon2] = weaponid;

            SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Duello mapini seçiniz.");

			ShowPlayerDialog(playerid, DIALOG_DUEL_MAP, DIALOG_STYLE_LIST, "{FF0000}LYNX DRIFT - {FFFFFF}Duello Map", "{FF0000}» {FFFFFF}T 25\n\
																													   {FF0000}» {FFFFFF}Stadium\n\
	 																												   {FF0000}» {FFFFFF}RC Battlefield", "Sec", "Iptal");
	    }
	}
	if(dialogid == DIALOG_DUEL_MAP)
	{
	    if(response)
	    {
	        new mapid;
	        switch(listitem)
	        {
	            case 0: mapid = 0;
	            case 1: mapid = 1;
	            case 2: mapid = 2;
	        }
			DuelInfo[playerid][d_Map] = mapid;
			DuelInfo[DuelInfo[playerid][d_Rakip]][d_Map] = mapid;

            if(!IsPlayerConnected(DuelInfo[playerid][d_Rakip])) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip oyunda değil.");
			if(DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip zaten bir duelloda.");
			if(GetPlayerMoney(playerid) < DuelInfo[playerid][d_Bet]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Duello bahsi kadar paranız yok.");
			if(DuelInfo[playerid][d_Bet] < 0) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Bahis negatif olamaz");

			new string[256];
			format(string, sizeof(string), "Duel » {FFFFFF}%s(%i)'a duello isteği attın.", PlayerName(DuelInfo[playerid][d_Rakip]), DuelInfo[playerid][d_Rakip]);
		    SendClientMessage(playerid, 0x99CC00FF, string);
			format(string, sizeof(string), "Duel » {FFFFFF}Duello silahlari %s ve %s.",ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon]), ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon2]));
			SendClientMessage(playerid, 0x99CC00FF, string);
			format(string, sizeof(string), "Duel » {FFFFFF}Duello bahsi $%i. Duello mapi %s", DuelInfo[playerid][d_Bet], ReturnMapName(DuelInfo[playerid][d_Map]));
			SendClientMessage(playerid, 0x99CC00FF, string);
	        format(string, sizeof(string), "{FF0000}» {FFFFFF}Rakip: %s(%i)\n\n\
											{FF0000}» {FFFFFF}Bahis miktari: $%i\n\n\
											{FF0000}» {FFFFFF}Silah 1: %s\n\
											{FF0000}» {FFFFFF}Silah 2: %s\n\n\
											{FF0000}» {FFFFFF}Map: %s", PlayerName(playerid), playerid, DuelInfo[playerid][d_Bet], ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon]), ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon2]) , ReturnMapName(DuelInfo[playerid][d_Map]));
	        ShowPlayerDialog(DuelInfo[playerid][d_Rakip], DIALOG_DUEL, DIALOG_STYLE_MSGBOX, "{FF0000}LYNX DRIFT - {FFFFFF}Duello", string, "Kabul", "Red");
	    }
 	}
	if(dialogid == DIALOG_DUEL)
	{
	    if(!response)
	    {
	        SendClientMessage(DuelInfo[playerid][d_Rakip], 0x99CC00FF, "Duel » {FFFFFF}Rakip duelloyu reddetti.");

	        DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel] = false;
	        DuelInfo[DuelInfo[playerid][d_Rakip]][d_Rakip] = INVALID_PLAYER_ID;
	        DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon] = 0;
	        DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon2] = 0;
	        DuelInfo[DuelInfo[playerid][d_Rakip]][d_Bet] = 0;

	        DuelInfo[playerid][d_induel] = false;
	        DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
	        DuelInfo[playerid][d_Weapon] = 0;
	        DuelInfo[playerid][d_Weapon2] = 0;
	        DuelInfo[playerid][d_Bet] = 0;
	    }else
	    if(response)
	    {
            if(!IsPlayerConnected(DuelInfo[playerid][d_Rakip])) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip oyunda değil.");
			if(DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip zaten bir duelloda.");
			if(GetPlayerMoney(playerid) < DuelInfo[playerid][d_Bet]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Duello bahsi kadar paranız yok.");
			if(DuelInfo[playerid][d_Bet] < 0) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Bahis negatif olamaz");

			ResetPlayerWeapons(playerid);
			GivePlayerWeapon(playerid, DuelInfo[playerid][d_Weapon], 5000);
			GivePlayerWeapon(playerid, DuelInfo[playerid][d_Weapon2], 5000);
			SetPlayerHealth(playerid, 100.0);
			SetPlayerArmour(playerid, 100.0);

			ResetPlayerWeapons(DuelInfo[playerid][d_Rakip]);
			GivePlayerWeapon(DuelInfo[playerid][d_Rakip], DuelInfo[playerid][d_Weapon], 5000);
			GivePlayerWeapon(DuelInfo[playerid][d_Rakip], DuelInfo[playerid][d_Weapon2], 5000);
			SetPlayerHealth(DuelInfo[playerid][d_Rakip], 100.0);
			SetPlayerArmour(DuelInfo[playerid][d_Rakip], 100.0);

			switch(DuelInfo[playerid][d_Map])
			{
			    case 0:
			    {
					SetPlayerPos(playerid, 1097.1639, 1063.6047, 10.8359);
					SetPlayerVirtualWorld(playerid, playerid+10);
                    			SetCameraBehindPlayer(playerid);

					SetPlayerPos(DuelInfo[playerid][d_Rakip], 1081.3628, 1080.4985, 10.8359);
					SetPlayerVirtualWorld(DuelInfo[playerid][d_Rakip], playerid+10);
					SetCameraBehindPlayer(DuelInfo[playerid][d_Rakip]);
				}
			    case 1:
			    {
					SetPlayerPos(playerid, 3374.6348, -1734.9648, 9.2609);
					SetPlayerVirtualWorld(playerid, playerid+10);
                    			SetCameraBehindPlayer(playerid);

					SetPlayerPos(DuelInfo[playerid][d_Rakip], 3341.7039, -1766.2764, 9.2609);
					SetPlayerVirtualWorld(DuelInfo[playerid][d_Rakip], playerid+10);
					SetCameraBehindPlayer(DuelInfo[playerid][d_Rakip]);
				}
			    case 2:
			    {
					SetPlayerPos(playerid, -1131.9055, 1057.8958, 1346.4146);
					SetPlayerInterior(playerid, 10);
					SetPlayerVirtualWorld(playerid, playerid+10);
                    			SetCameraBehindPlayer(playerid);

					SetPlayerPos(DuelInfo[playerid][d_Rakip], -974.6671, 1060.8036, 1345.6719);
					SetPlayerInterior( DuelInfo[playerid][d_Rakip], 10);
					SetPlayerVirtualWorld( DuelInfo[playerid][d_Rakip], playerid+10);
					SetCameraBehindPlayer(DuelInfo[playerid][d_Rakip]);
				}
			}
			TogglePlayerControllable(playerid, false);
			TogglePlayerControllable(DuelInfo[playerid][d_Rakip], false);

			Duello_Sayac[playerid] = 6;
			KillTimer(Duello_Timer[playerid]);
	 		Duello_Timer[playerid] = SetTimerEx("Duello_Sayim", 1000, true, "i", playerid);

			Duello_Sayac[DuelInfo[playerid][d_Rakip]] = 6;
			KillTimer(Duello_Timer[DuelInfo[playerid][d_Rakip]]);
	 		Duello_Timer[DuelInfo[playerid][d_Rakip]] = SetTimerEx("Duello_Sayim", 1000, true, "i", DuelInfo[playerid][d_Rakip]);

	        	DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel] = true;
	        	DuelInfo[playerid][d_induel] = true;
			return 1;
	    }
	}
	return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
	if(DuelInfo[playerid][d_induel])
	{
	    	SendClientMessage(playerid,0xFF0000FF, "Hata » {FFFFFF}Su an duelloda bulunuyorsunuz. Duello bitmeden komut kullanamazsınız.");
		return 1;
	}
	return 1;
}
CMD:duel(playerid, params[])
{
	if(DuelInfo[playerid][d_induel]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Zaten duellodasınız.");
	new target, bet;
	if(sscanf(params, "ii", target, bet)) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}/duel [player] [bahis]");
	if(!IsPlayerConnected(target)) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip oyunda değil.");
	if(DuelInfo[target][d_induel]) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Rakip zaten bir duelloda.");
	if(GetPlayerMoney(playerid) < bet) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Duello bahsi kadar paranız yok.");
	if(bet < 0) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Bahis negatif olamaz");
	if(target == playerid) return SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}Kendine duello isteği atamazsın.");

	DuelInfo[playerid][d_Rakip] = target;
	DuelInfo[target][d_Rakip] = playerid;

	DuelInfo[playerid][d_Bet] = bet;
	DuelInfo[DuelInfo[playerid][d_Rakip]][d_Bet] = bet;

	SendClientMessage(playerid, 0x99CC00FF, "Duel » {FFFFFF}1. duello silahını seçiniz.");
 	new str[512];
  	format(str, 512, "{FF0000}» {FFFFFF}Testere\n{FF0000}» {FFFFFF}El Bombası\n{FF0000}» {FFFFFF}Molotof\n{FF0000}» {FFFFFF}9mm\n{FF0000}» {FFFFFF}Silenced\n{FF0000}» {FFFFFF}Deagle\n{FF0000}» {FFFFFF}Shotgun\n{FF0000}» {FFFFFF}Sawn Off\n{FF0000}» {FFFFFF}Combat\n{FF0000}» {FFFFFF}Uzi\n{FF0000}» {FFFFFF}Mp5\n{FF0000}» {FFFFFF}Ak-47\n{FF0000}» {FFFFFF}M4\n{FF0000}» {FFFFFF}Tec-9\n{FF0000}» {FFFFFF}Rifle\n{FF0000}» {FFFFFF}Sniper");
	ShowPlayerDialog(playerid, DIALOG_DUEL_WEAPON, DIALOG_STYLE_LIST, "{FF0000}LYNX DRIFT - {FFFFFF}Duello Silah 1", str, "Sec", "Iptal");
	return 1;
}
ReturnWeaponNameEx(weaponid)
{
	new weaponstr[45];
	switch(weaponid)
	{
	    case 0: weaponstr = "Fist";
	    case 18: weaponstr = "Molotov Cocktail";
            case 44: weaponstr = "Night Vision Goggles";
            case 45: weaponstr = "Thermal Goggles";
            default: GetWeaponName(weaponid, weaponstr, sizeof(weaponstr));
	}
	return weaponstr;
}
ReturnMapName(mapid)
{
	new mapstr[56];
	switch(mapid)
	{
	    case 0: mapstr = "T 25";
	    case 1: mapstr = "Stadium";
      	    case 2: mapstr = "RC Battlefield";
	}
	return mapstr;
}
forward Duello_Sayim(playerid);
public Duello_Sayim(playerid)
{
	switch(Duello_Sayac[playerid])
	{
	    case 0:
	    {
	    	GameTextForPlayer(playerid, "~r~~h~Basla!", 2000, 5),PlayerPlaySound(playerid,1057,0.0,0.0,0.0);
		KillTimer(Duello_Timer[playerid]);
		TogglePlayerControllable(playerid, true);
		DuelInfo[playerid][d_Tick] = GetTickCount();
		DuelInfo[DuelInfo[playerid][d_Rakip]][d_Tick] = GetTickCount();
	    }
	    case 1: GameTextForPlayer(playerid, "~r~~h~~h~~h~1", 1000, 5),PlayerPlaySound(playerid,1056,0.0,0.0,0.0);
	    case 2: GameTextForPlayer(playerid, "~b~~h~~h~~h~2", 1000, 5),PlayerPlaySound(playerid,1056,0.0,0.0,0.0);
	    case 3: GameTextForPlayer(playerid, "~g~~h~~h~~h~3", 1000, 5),PlayerPlaySound(playerid,1056,0.0,0.0,0.0);
	    case 4: GameTextForPlayer(playerid, "~g~~h~~h~4", 1000, 5),PlayerPlaySound(playerid,1056,0.0,0.0,0.0);
	    case 5: GameTextForPlayer(playerid, "~g~~h~5", 1000, 5),PlayerPlaySound(playerid,1056,0.0,0.0,0.0);
	    case 6: GameTextForPlayer(playerid, "~g~HAZIR", 1000, 5);
	}
	Duello_Sayac[playerid]--;
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	if(DuelInfo[playerid][d_induel])
	{
	    new string[144];
	    GivePlayerMoney(DuelInfo[playerid][d_Rakip], DuelInfo[playerid][d_Bet]);
	    GivePlayerMoney(playerid, -DuelInfo[playerid][d_Bet]);
	    format(string, sizeof(string), "Duel » {FFFFFF}%s duelloda %s'yı mağlup etti. Silahlar: {FF9900}%s & %s {FFFFFF}Bahis: {FF9900}$%i {FFFFFF}(%s)", PlayerName(DuelInfo[playerid][d_Rakip]), PlayerName(playerid), ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon]),ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon2]), DuelInfo[playerid][d_Bet], ConvertTime(GetTickCount() - DuelInfo[playerid][d_Tick]));
	    SendClientMessageToAll(0x99CC00FF, string);

            DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel] = false;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Rakip] = INVALID_PLAYER_ID;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon2] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Bet] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Map] = 0;

        DuelInfo[playerid][d_induel] = false;
        DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
        DuelInfo[playerid][d_Weapon] = 0;
        DuelInfo[playerid][d_Weapon2] = 0;
        DuelInfo[playerid][d_Bet] = 0;
        DuelInfo[playerid][d_Map] = 0;

        SpawnPlayer(killerid);
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
	if(DuelInfo[playerid][d_induel])
	{
	    GivePlayerMoney(DuelInfo[playerid][d_Rakip], DuelInfo[playerid][d_Bet]);
	    GivePlayerMoney(playerid, -DuelInfo[playerid][d_Bet]);
	    new string[144];
	    format(string, sizeof(string), "Duel » {FFFFFF}%s duelloda %s'yı mağlup etti. Silahlar: {FF9900}%s & %s {FFFFFF}Bahis: {FF9900}$%i {FFFFFF}(%s)", PlayerName(DuelInfo[playerid][d_Rakip]), PlayerName(playerid), ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon]),ReturnWeaponNameEx(DuelInfo[playerid][d_Weapon2]), DuelInfo[playerid][d_Bet], ConvertTime(GetTickCount() - DuelInfo[playerid][d_Tick]));
	    SendClientMessageToAll(0x99CC00FF, string);

       	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_induel] = false;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Rakip] = INVALID_PLAYER_ID;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Weapon2] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Bet] = 0;
	    DuelInfo[DuelInfo[playerid][d_Rakip]][d_Map] = 0;

        DuelInfo[playerid][d_induel] = false;
        DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
        DuelInfo[playerid][d_Weapon] = 0;
        DuelInfo[playerid][d_Weapon2] = 0;
        DuelInfo[playerid][d_Bet] = 0;
        DuelInfo[playerid][d_Map] = 0;
	}
	DuelInfo[playerid][d_induel] = false;
 	DuelInfo[playerid][d_Rakip] = INVALID_PLAYER_ID;
	DuelInfo[playerid][d_Weapon] = 0;
	DuelInfo[playerid][d_Weapon2] = 0;
	DuelInfo[playerid][d_Bet] = 0;
	DuelInfo[playerid][d_Map] = 0;
	return 1;
}
stock PlayerName(playerid)
{
	new oName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, oName, sizeof oName);
	return oName;
}
stock ConvertTime(time)
{
	new str[16];
    new minutes=time/60000;
    new ms=time-((minutes)*60000);
    new seconds=(ms)/1000;
    ms-=seconds*1000;
	format(str, sizeof(str), "%02d:%02d.%03d", minutes, seconds, ms);
	return str;
}
