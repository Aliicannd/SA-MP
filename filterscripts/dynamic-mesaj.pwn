#define FILTERSCRIPT

#include <a_samp>
#include <a_mysql>
#include <foreach>
#include <sscanf2>
#include <zcmd>

#define	SQL_HOST	 "127.0.0.1"
#define	SQL_USER	 "root"
#define	SQL_PASSWORD ""
#define	SQL_DBNAME	 "mesajlar"
new MySQL: handle;

#define MAX_MESAJ 30
#define MESAJ_DAKIKA 3//Kaç dakika aralıkla mesaj göndereceğini ayarlayın
#define MESAJ_RENK 0xFFFF00FF
#define MESAJ_PREFIX "Otomatik Mesaj: {FFFFFF}"
#define DIALOG_MESAJLAR 1257

enum mesajenum
{
	Mesaj[128],
	Ekleyen[MAX_PLAYER_NAME]
}
new MesajData[MAX_MESAJ][mesajenum];
new Iterator: Mesajlar<MAX_MESAJ>;
new MesajTimer;

public OnFilterScriptInit()
{
	handle = mysql_connect(SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DBNAME);
	mysql_log(ERROR | WARNING);
	if(mysql_errno() != 0) return print("MySQL Bağlantı Hatasi!");
	
	mysql_tquery(handle, "CREATE TABLE IF NOT EXISTS `mesajlar` (`id` INT(11), `mesaj` VARCHAR(128), `ekleyen` VARCHAR(24), PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;");
	mysql_tquery(handle, "SELECT * FROM `mesajlar`", "MesajYukle");
	
	MesajTimer = SetTimer("OtomatikMesajYolla", 60000*MESAJ_DAKIKA, true);
	return 1;
}

public OnFilterScriptExit()
{
	KillTimer(MesajTimer);
	mysql_close(handle);
	return 1;
}

forward MesajYukle();
public MesajYukle()
{
	new rows = cache_num_rows();
	if(rows)
	{
		new id, loaded;
		while(loaded < rows)
		{
			cache_get_value_name_int(loaded, "id", id);
			cache_get_value_name(loaded, "mesaj", MesajData[id][Mesaj], 128);
			cache_get_value_name(loaded, "ekleyen", MesajData[id][Ekleyen], MAX_PLAYER_NAME);
			Iter_Add(Mesajlar, id);
			loaded++;
		}
		printf("%d adet mesaj yuklendi.", loaded);
	}
	return 1;
}
forward OtomatikMesajYolla();
public OtomatikMesajYolla()
{
    if(Iter_Count(Mesajlar) > 1)
    {
		new id = Iter_Random(Mesajlar);
		new mesaj[156];
		format(mesaj, sizeof(mesaj), ""#MESAJ_PREFIX"%s", MesajData[id][Mesaj]);
		SendClientMessageToAll(MESAJ_RENK, mesaj);
    }
	return 1;
}
CMD:mesajekle(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid,-1,"Bu komutu kullanabilmek için admin olmalısın.");
	new mesaj[128];
	if(sscanf(params, "s[128]", mesaj)) return SendClientMessage(playerid,-1,"/mesajekle [Mesaj]");
	new id = Iter_Free(Mesajlar);
	if(id == -1) return SendClientMessage(playerid,-1,"Daha fazla mesaj ekleyemezsiniz. Max "#MAX_MESAJ"");
	Iter_Add(Mesajlar, id);
	GetPlayerName(playerid, MesajData[id][Ekleyen], MAX_PLAYER_NAME);
	format(MesajData[id][Mesaj], 128, mesaj);
	
	new query[256];
	mysql_format(handle, query, sizeof(query), "INSERT INTO `mesajlar` (`id`, `mesaj`, `ekleyen`) VALUES ('%d', '%e', '%e')", id, MesajData[id][Mesaj], MesajData[id][Ekleyen]);
	mysql_tquery(handle, query);
	return 1;
}
CMD:mesajsil(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid,-1,"Bu komutu kullanabilmek için admin olmalısın.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid,-1,"/mesajsil [id]");
	if(!(0 <= id <= MAX_MESAJ)) return SendClientMessage(playerid,-1,"Geçersiz ID.");
	if(!Iter_Contains(Mesajlar, id)) return SendClientMessage(playerid,-1,"Böyle bir mesaj idsi yok.");

	MesajData[id][Mesaj][0] = '\0';
	MesajData[id][Ekleyen][0] = '\0';
	Iter_Remove(Mesajlar, id);

	new query[64];
	mysql_format(handle, query, sizeof(query), "DELETE FROM `mesajlar` WHERE `id` = %d", id);
	mysql_tquery(handle, query);
	return 1;
}
CMD:mesajlar(playerid)
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid,-1,"Bu komutu kullanabilmek için admin olmalısın.");
	new dialog[MAX_MESAJ*156];
	foreach(new i: Mesajlar)
	{
	    format(dialog, sizeof(dialog), "%s{FFFFFF}%d) {2ECC71}%s\t{FFFFFF}%s\n", dialog, i, MesajData[i][Mesaj], MesajData[i][Ekleyen]);
	}
	ShowPlayerDialog(playerid, DIALOG_MESAJLAR, DIALOG_STYLE_LIST, "Mesajlar", dialog, "Tamam", "");
	return 1;
}
