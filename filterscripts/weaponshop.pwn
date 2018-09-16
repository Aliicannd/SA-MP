#define FILTERSCIPT
#include <a_samp>
#include <zcmd>

#define	DIALOG_SILAH 1232

enum slh
{
	WeapID,
	WeapName[64],
	WeapPrice[60],
	WeapAmmo
}
new Silahlar[15][slh] =
{
	//{Silah id, "Silah ismi", fiyat, WeapAmmo},
	{4, "Knife", 10, 1},
	{8, "Katana", 10, 1},
	{9, "Chainsaw", 100, 1},
	{10, "Purple Dildo", 50, 1},
	{16, "Grenade", 200, 10},
	{18, "Molotov Cocktail", 300, 5},
	{23, "Silenced 9mm", 1000, 50},
	{24, "Desert Eagle", 2000, 100},
	{25, "Shotgun", 2000, 50},
	{26, "Sawnoff Shotgun", 2000, 50},
	{27, "Combat Shotgun", 2000, 50},
	{28, "Uzi", 1000, 100},
	{31, "M4", 2000, 100},
	{34, "Sniper Rifle", 2000, 50},
	{26, "Sawnoff Shotgun", 2000, 50}
};

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_SILAH)
	{
		if(response)
		{
			if(GetPlayerMoney(playerid) <= Silahlar[listitem][WeapPrice]) return SendClientMessage(playerid, 0xFF0000FF, "Hata: {FFFFFF}Yeterli paranız yok.");
			new string[128];
			format(string, sizeof(string), "Bilgi: {FFFFFF}%s isimli silahı $%d'a aldınız.", Silahlar[listitem][WeapName], Silahlar[listitem][WeapPrice]);
			SendClientMessage(playerid, 0x66FF00FF, string);
			GivePlayerMoney(playerid, -Silahlar[listitem][WeapPrice]);
			GivePlayerWeapon(playerid, Silahlar[listitem][WeapID], Silahlar[listitem][WeapAmmo]);
		}
		return 1;
	}
	return 1;
}
CMD:silahlar(playerid, params[])
{
	new string[2048];
	for(new x = 0; x < sizeof(Silahlar); x++)
	{
		format(string, sizeof(string), "%s%s - $%d\n", string, Silahlar[x][WeapName], Silahlar[x][WeapPrice]);
	}
	ShowPlayerDialog(playerid, DIALOG_SILAH, DIALOG_STYLE_LIST, "Silah Dükkanı", string, "Satinal", "{FF0000}Iptal");
	return 1;
}
