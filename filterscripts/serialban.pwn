#define FILTERSCRIPT
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <zcmd>

#if !defined gpci
    native gpci(playerid, serial[], len);
#endif

#define SQL_HOST "localhost"
#define SQL_USER "root"
#define SQL_PASS ""
#define SQL_DATABASE "sban"

#define DIALOG_BANLISTE 2457

new MySQL:dbHandle;

public OnFilterScriptInit()
{
	dbHandle = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DATABASE);
	mysql_tquery(dbHandle, "CREATE TABLE IF NOT EXISTS `sbans` (`isim` VARCHAR(24) DEFAULT NULL, `serial` VARCHAR(41) DEFAULT NULL, `admin` VARCHAR(24) DEFAULT NULL, `sebep` VARCHAR(64) DEFAULT NULL)");
	return 1;
}
public OnFilterScriptExit()
{
	mysql_close(dbHandle);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new szSerial[41];
	gpci(playerid, szSerial, sizeof(szSerial));
	
	new query[256];
	mysql_format(dbHandle, query, sizeof(query), "SELECT * FROM `sbans` WHERE `serial` = '%s'", szSerial);
	new Cache:alican = mysql_query(dbHandle, query);
	if(cache_num_rows())
	{
		SetTimerEx("BanlaOnu", 200, false, "d", playerid);
	}
	cache_delete(alican);
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_BANLISTE)
	{
		if(!response) return 1;
		new var[16], szSerial[41];
		format(var, sizeof(var), "SbanListe_%d", listitem);
		GetPVarString(playerid, var, szSerial, 41);

		new query[128];
		mysql_format(dbHandle, query, sizeof(query), "DELETE FROM `sbans` WHERE `serial` = '%s'", szSerial);
		mysql_query(dbHandle, query, false);
		return 1;
	}
	return 1;
}
CMD:sban(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Admin olmalısın.");
	new pID, sebep[64];
	if(sscanf(params, "us[64]", pID, sebep)) return SendClientMessage(playerid, -1, "/sban <ID> <Sebep>");
	if(!IsPlayerConnected(pID)) return SendClientMessage(playerid, -1, "Oyuncu oyunda değil.");

	new isim[MAX_PLAYER_NAME], admin[MAX_PLAYER_NAME], szSerial[41];
	GetPlayerName(pID, isim, MAX_PLAYER_NAME);
	GetPlayerName(playerid, admin, MAX_PLAYER_NAME);
	gpci(pID, szSerial, sizeof(szSerial));

	new query[256];
	mysql_format(dbHandle, query, sizeof(query), "INSERT INTO `sbans` (`isim`, `serial`, `admin`, `sebep`) VALUES ('%e', '%s', '%e', '%e')", isim, szSerial, admin, sebep);
	mysql_query(dbHandle, query, false);

	format(query, sizeof(query), "%s isimli admin %s isimli oyuncuyu banladı. Sebep %s", admin, isim, sebep);
	SendClientMessageToAll(-1, query);
	SetTimerEx("BanlaOnu", 200, false, "d", pID);
	return 1;
}
CMD:banliste(playerid)
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Admin olmalısın.");
	mysql_tquery(dbHandle, "SELECT * FROM `sbans`", "BanListele", "d", playerid);
	return 1;
}
forward BanListele(playerid);
public BanListele(playerid)
{
	new rows = cache_num_rows();
	if(!rows) return SendClientMessage(playerid, -1, "Hiçbir ban bulunamadı");
	new var[16], isim[MAX_PLAYER_NAME], admin[MAX_PLAYER_NAME], szSerial[41], sebep[64];
	new dialog[1024] = "{FFFFFF}Isim\t{FFFFFF}Admin\t{FFFFFF}Sebep\n";
	for(new i; i < rows; i++)
	{
		format(var, sizeof(var), "SbanListe_%d", i);
		cache_get_value_name(i, "isim", isim, MAX_PLAYER_NAME);
		cache_get_value_name(i, "serial", szSerial, 41);
		SetPVarString(playerid, var, szSerial);
		cache_get_value_name(i, "admin", admin, MAX_PLAYER_NAME);
		cache_get_value_name(i, "sebep", sebep, 64);
		format(dialog, sizeof(dialog), "%s{FFFFFF}%s\t%s\t%s\n", dialog, isim, admin, sebep);
	}
	ShowPlayerDialog(playerid, DIALOG_BANLISTE, DIALOG_STYLE_TABLIST_HEADERS, "Ban Listesi", dialog, "Ban Ac", "Geri");
	return 1;
}
forward BanlaOnu(playerid);
public BanlaOnu(playerid)
{
	Ban(playerid);
	return 1;
}
