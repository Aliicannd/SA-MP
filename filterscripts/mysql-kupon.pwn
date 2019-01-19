/*
	MySQL kupon sistemi.
	Kodlayan Jawié
*/
#define FILTERSCRIPT
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <zcmd>

#define	MYSQL_HOST 			"localhost"
#define	MYSQL_USER 			"root"
#define	MYSQL_PASSWORD 		""
#define	MYSQL_DATABASE 		"kupon"

new MySQL:exHandle;
#define HEDIYE_KUPON_DIALOG 3475

#define KULLANIMI "{2A90D4}[Kullanım]: {FFFFFF}"
#define HATASI "{D42AB2}[Hata]: {FFFFFF}"
#define BILGISI "{81F553}[Bilgi]: {FFFFFF}"

public OnFilterScriptInit()
{
	mysql_log(ERROR);
	exHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	if(exHandle == MYSQL_INVALID_HANDLE || mysql_errno(exHandle) != 0)
	{
		print("MySQL bağlantısı sağlanamadı!");
	}else
	{
		print("MySQL başarıyla bağlandı!");
		mysql_tquery(exHandle,	"CREATE TABLE IF NOT EXISTS `kuponlar` (`kod` varchar(20) NOT NULL, `para` int(11) NOT NULL, `skor` int(11) NOT NULL)");
	}
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(exHandle);
	return 1;
}

CMD:kodekle(playerid, params[])
{
	new kod[20], skor, para;
	if(sscanf(params, "iis[20]", skor, para, kod)) return SendClientMessage(playerid, -1, ""KULLANIMI"/kodekle (SKOR) (PARA) (KOD)");
	new query[128];
	mysql_format(exHandle, query, sizeof(query), "SELECT * FROM `kuponlar` WHERE `kod` = '%e'", kod);
	new Cache:alican = mysql_query(exHandle, query);
	if(cache_num_rows())
	{
		SendClientMessage(playerid, -1, ""HATASI"Bu kod daha önce girilmiş.");
	}else
	{
		mysql_format(exHandle, query, sizeof(query), "INSERT INTO `kuponlar` (`kod`, `para`, `skor`) VALUES ('%e', '%d', '%d')", kod, para, skor);
		mysql_tquery(exHandle, query);
		printf("Yeni bir hediye kodu olusturuldu: %s", kod);
		SendClientMessage(playerid, -1, ""BILGISI"Başarıyla yeni hediye kodunuz oluşturuldu. Oyuncular '/hediyekodu' komutu ile kodu girdiği takdirde ödülü alacaktır.");
	}
	cache_delete(alican);
	return 1;
}
CMD:kodsil(playerid, params[])
{
	new kod[20];
	if(sscanf(params, "s[20]", kod)) return SendClientMessage(playerid, -1, "/kodsil (KOD)");
	new query[128];
	mysql_format(exHandle, query, sizeof(query), "SELECT * FROM `kuponlar` WHERE `kod` = '%e'", kod);
	new Cache:alican = mysql_query(exHandle, query);
	if(cache_num_rows())
	{
		mysql_format(exHandle, query, sizeof(query), "DELETE FROM `kuponlar` WHERE `kod` = '%e'", kod);
		mysql_tquery(exHandle, query);
		printf("%s isimli kod basariyla silindi!", kod);
		SendClientMessage(playerid, -1, ""BILGISI"Başarıyla hediye kodunu sildiniz, artık kullanılamaz.");
	}else
	{
		SendClientMessage(playerid, -1, ""HATASI"Bu kod daha önce girilmemiş.");
	}
	cache_delete(alican);
	return 1;
}

CMD:hediyekodu(playerid, params[])
{
	ShowPlayerDialog(playerid, HEDIYE_KUPON_DIALOG, DIALOG_STYLE_INPUT, "{4DA6D6}Hediye Kuponu", "{FFFFFF}Lütfen aşağıya kuponunuzun kodunu giriniz.", "Tamam", "Iptal");
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == HEDIYE_KUPON_DIALOG)
	{
		if(!strlen(inputtext)) return SendClientMessage(playerid, -1, ""HATASI"Girmiş olduğunuz kupon geçersiz.");
		new query[128];
		mysql_format(exHandle, query, sizeof(query), "SELECT * FROM `kuponlar` WHERE `kod` = '%e'", inputtext);
		new Cache:alican = mysql_query(exHandle, query);
		if(cache_num_rows())
		{
			new para, skor;
			cache_get_value_name_int(0, "para", para);
			cache_get_value_name_int(0, "skor", skor);

			SetPlayerScore(playerid, GetPlayerScore(playerid)+skor);
			GivePlayerMoney(playerid, para);
			mysql_format(exHandle, query, sizeof(query), "DELETE FROM `kuponlar` WHERE `kod` = '%e'", inputtext);
			mysql_tquery(exHandle, query);
			SendClientMessage(playerid, -1, ""BILGISI"Kuponu kullandınız, artık kullanılamaz.");
		}else
		{
			SendClientMessage(playerid, -1, ""HATASI"Bu kod daha önce girilmemiş.");
		}
		cache_delete(alican);
	}
	return 1;
}
