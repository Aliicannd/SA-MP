#define FILTERSCRIPT
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <streamer>
#include <zcmd>
#include <foreach>

#define	SQL_HOST		"localhost"
#define	SQL_USER		"root"
#define	SQL_PASSWORD	""
#define	SQL_DATABASE	"speed"

new MySQL:recorddb;

#define MAX_SPEED 25

enum speed_data
{
	speedRecord,
	speedName[56],
	speedOwner[MAX_PLAYER_NAME],
	Float: speedX,
	Float: speedY,
	Float: speedZ,
	speedArea,
	speedIcon
};
new SpeedData[MAX_SPEED][speed_data];
new Iterator: SpeedIter<MAX_SPEED>;

public OnFilterScriptInit()
{
	recorddb = mysql_connect(SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DATABASE);
	mysql_log(ERROR | WARNING);
	if (recorddb == MYSQL_INVALID_HANDLE || mysql_errno(recorddb) != 0)
	{
		print("MySQL baglanti hatasi.");
		SendRconCommand("exit");
		return 1;
	}
	mysql_tquery(recorddb, "CREATE TABLE IF NOT EXISTS `speeds` (\
														`ID` INT(11) NOT NULL,\
														`speedRecord` INT(11) NOT NULL DEFAULT '0',\
														`speedName` VARCHAR(56) NOT NULL,\
														`speedOwner` VARCHAR(24) NOT NULL DEFAULT 'Yok',\
														`speedX` VARCHAR(16) NOT NULL,\
														`speedY` VARCHAR(16) NOT NULL,\
														`speedZ` VARCHAR(16) NOT NULL,\
														PRIMARY KEY (`ID`))");
	mysql_tquery(recorddb, "SELECT * FROM `speeds`", "SpeedYukle");
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(recorddb);
	return 1;
}
forward SpeedYukle();
public SpeedYukle()
{
	new rows = cache_num_rows();
	if(rows)
	{
		new x, loaded;
		while(loaded < rows)
		{
			cache_get_value_name_int(loaded, "ID", x);
			cache_get_value_name_int(loaded, "speedRecord", SpeedData[x][speedRecord]);
			cache_get_value_name(loaded, "speedName", SpeedData[x][speedName], 56);
			cache_get_value_name(loaded, "speedOwner", SpeedData[x][speedOwner], MAX_PLAYER_NAME);
			cache_get_value_name_float(loaded, "speedX", SpeedData[x][speedX]);
			cache_get_value_name_float(loaded, "speedY", SpeedData[x][speedY]);
			cache_get_value_name_float(loaded, "speedZ", SpeedData[x][speedZ]);
			Iter_Add(SpeedIter, x);
			SpeedData[x][speedArea] = CreateDynamicSphere(SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ], 8.0, 0, 0);
			SpeedData[x][speedIcon] = CreateDynamicMapIcon(SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ], 56, 0, 0, 0, -1, 500.0);
			loaded++;
		}
		printf("[INIT] %d speed yuklendi.", loaded);
	}
	return 1;
}
stock GetVehicleSpeed(playerid)
{
	new Float:x, Float:y, Float:z;
	GetVehicleVelocity(GetPlayerVehicleID(playerid), x, y, z);
	return floatround(floatsqroot(x*x+y*y+z*z)*200.2);
}
public OnPlayerEnterDynamicArea(playerid, areaid)
{
	foreach(new d: SpeedIter)
	{
 		if(areaid == SpeedData[d][speedArea])
 		{
			if(GetPlayerState(playerid) == 2)
			{
				new hiz = GetVehicleSpeed(playerid);
			  	if(hiz > 80 && hiz > SpeedData[d][speedRecord])
			  	{
			  		new str[256];
					GetPlayerName(playerid, SpeedData[d][speedOwner], 24);
					SpeedData[d][speedRecord] = hiz;
				  	format(str, sizeof(str), "Speed: {FFFFFF}%s yeni bir hız rekoru kırdı! %d km/h ({0DFF00}%s{FFFFFF})", SpeedData[d][speedOwner], SpeedData[d][speedRecord], SpeedData[d][speedName]);
				  	SendClientMessageToAll(0xFF0000FF, str);
				  	new Float:x, Float:y, Float:z;
				  	GetPlayerCameraPos(playerid, x, y, z), SetPlayerCameraPos(playerid, x, y, z+10);
				  	GetPlayerPos(playerid, x, y, z), SetPlayerCameraLookAt(playerid, x, y, z);
				  	SetTimerEx("SetBackToNormalCam", 2000, false, "i", playerid);
				  	format(str, sizeof(str), "~g~~h~~h~%d KM/H", hiz);
				  	GameTextForPlayer(playerid, str, 3000, 3);
				  	GivePlayerMoney(playerid, 1000);

					mysql_format(recorddb, str, sizeof(str), "UPDATE `speeds` SET `speedRecord` = '%d', `speedOwner` = '%e' WHERE `ID` = '%d'", SpeedData[d][speedRecord], SpeedData[d][speedOwner], d);
					mysql_tquery(recorddb, str);
		  		}
			}
 		}
	}
	return 1;
}
forward SetBackToNormalCam(playerid);
public SetBackToNormalCam(playerid)
{
	SetCameraBehindPlayer(playerid);
	return 1;
}
CMD:speedekle(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid,-1,"Bu komutu kullanabilmek için admin olmalısın.");
	new zone[56];
	if(sscanf(params, "s[56]", zone)) return SendClientMessage(playerid,-1,"/speedekle [Isim]");
	new x = Iter_Free(SpeedIter);
	if(x == -1) return SendClientMessage(playerid,-1,"Daha fazla speed noktası ekleyemezsiniz. Max "#MAX_SPEED"");
	Iter_Add(SpeedIter, x);
	GetPlayerPos(playerid, SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ]);
	SpeedData[x][speedArea] = CreateDynamicSphere(SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ], 8.0, 0, 0);
	SpeedData[x][speedIcon] = CreateDynamicMapIcon(SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ], 56, 0, 0, 0, -1, 500.0);
	format(SpeedData[x][speedName], 56, zone);
	new query[256];
	mysql_format(recorddb, query, sizeof(query), "INSERT INTO `speeds` (`ID`, `speedName`, `speedX`, `speedY`, `speedZ`) VALUES ('%d', '%e', '%f', '%f', '%f')", x, SpeedData[x][speedName], SpeedData[x][speedX], SpeedData[x][speedY], SpeedData[x][speedZ]);
	mysql_tquery(recorddb, query);
	return 1;
}
CMD:speedsil(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid,-1,"Bu komutu kullanabilmek için admin olmalısın.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid,-1,"/speedsil [id]");
	if(!(0 <= id <= MAX_SPEED)) return SendClientMessage(playerid,-1,"Geçersiz ID.");
	if(!Iter_Contains(SpeedIter, id)) return SendClientMessage(playerid,-1,"Böyle bir speed noktası yok.");
	
	SpeedData[id][speedName][0] = '\0';
	SpeedData[id][speedOwner][0] = '\0';
	SpeedData[id][speedX] = 0.0;
	SpeedData[id][speedY] = 0.0;
	SpeedData[id][speedZ] = 0.0;
	DestroyDynamicArea(SpeedData[id][speedArea]);
	DestroyDynamicMapIcon(SpeedData[id][speedIcon]);
	Iter_Remove(SpeedIter, id);

	new query[64];
	mysql_format(recorddb, query, sizeof(query), "DELETE FROM `speeds` WHERE `ID` = %d", id);
	mysql_tquery(recorddb, query);
	return 1;
}
CMD:rekorlar(playerid)
{
	new str[1024];
	format(str, sizeof(str), "{FFFFFF}#\t{FFFFFF}Bolge\t{FFFFFF}Rekor\t{FFFFFF}Sahip\n");
	foreach(new x: SpeedIter)
	{
		format(str, sizeof(str), "%s{FFFFFF}%d\t%s\t%d\t%s\n", str, x+1, SpeedData[x][speedName], SpeedData[x][speedRecord], SpeedData[x][speedOwner]);
	}
	ShowPlayerDialog(playerid, 2012, DIALOG_STYLE_TABLIST_HEADERS, "Hız Rekorları", str, "Tamam", "");
	return 1;
}
