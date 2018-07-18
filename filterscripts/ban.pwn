#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <TimestampToDate>
#include <zcmd>

#define SQL_HOST	"localhost"
#define SQL_USER	"root"
#define SQL_PASS	""
#define SQL_DATA	"bann"

new MySQL: g_SQL;

#define DIALOG_BAN 322

public OnFilterScriptInit()
{
	g_SQL = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DATA);
	mysql_log(ALL);

	mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS `bans` (\
													`ban_name` varchar(24) NOT NULL,\
													`ban_admin` varchar(24) NOT NULL,\
													`ban_reason` varchar(30) NOT NULL,\
													`ban_time` int(11) NOT NULL,\
													UNIQUE KEY `ban_name` (`ban_name`))");
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(g_SQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new namem[MAX_PLAYER_NAME], query[128];
	GetPlayerName(playerid, namem, MAX_PLAYER_NAME);
	mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM `bans` WHERE `ban_name` = '%e' LIMIT 1", namem);
	mysql_tquery(g_SQL, query, "BanKontrol", "i", playerid);
	return 1;
}
CMD:ban(playerid, params[])
{
	new reason[30], pID, time;
	if(sscanf(params, "us[30]i", pID, reason, time)) return SendClientMessage(playerid, -1, "/ban <Name/ID> <Reason> <Time [in days] (ban time 0 = permanent>");
	if(strlen(reason) > 30) return SendClientMessage(playerid, -1, "Reason must not exceed 30 characters!");
	if(!IsPlayerConnected(pID)) return SendClientMessage(playerid, -1, "Player is not connected!");

	new admin[MAX_PLAYER_NAME], user[MAX_PLAYER_NAME], str[512], expiree;
	GetPlayerName(pID, user, MAX_PLAYER_NAME), GetPlayerName(playerid, admin, MAX_PLAYER_NAME);
	expiree = gettime() + (60*60*24*time);
	mysql_format(g_SQL, str, sizeof(str), "INSERT INTO `bans` (ban_name, ban_admin, ban_reason, ban_time) VALUES ('%e', '%e', '%e', %i)", user, admin, reason, expiree);
	mysql_tquery(g_SQL, str);

	switch(time)
	{
	    case 0:
	    {
			format(str, sizeof(str), "Administrator has banned %s(%i)! [Reason: %s] [Ban Time: Permanent]", user, pID, reason);
			SendClientMessageToAll(-1, str);

			format(str, sizeof(str), "{FF0000}You are banned from the server!\n\n\
								      {FFFFFF}Expire: {FF0000}Permanent\n\
									  {FFFFFF}Admin: {C3C3C3}%s\n\
									  {FFFFFF}Reason: {C3C3C3}%s", admin, reason);
	 		ShowPlayerDialog(pID, DIALOG_BAN, DIALOG_STYLE_MSGBOX, "{FF0000}You are banned!", str, "Okay", "");
	 		Kick(pID);
	    }
	    default:
	    {
			format(str, sizeof(str), "Administrator has banned %s(%i)! [Reason: %s] [Ban Time: %i day(s)]", user, pID, reason, time);
			SendClientMessageToAll(-1, str);

	        new d, m, y, h, mi, s;
			TimestampToDate(expiree, y , m, d, h, mi, s, 0, 0);
			format(str, sizeof(str), "{FF0000}You are banned from the server!\n\n\
									  {FFFFFF}Expire: {C3C3C3}%i/%i/%i [DD/MM/YY] | %i:%i\n\
									  {FFFFFF}Admin: {C3C3C3}%s\n\
									  {FFFFFF}Reason: {C3C3C3}%s", d, m, y, h, mi, admin, reason);
			ShowPlayerDialog(pID, DIALOG_BAN, DIALOG_STYLE_MSGBOX, "{FF0000}You are banned!", str, "Okay", "");
			Kick(pID);
	    }
	}
	return 1;
}

CMD:unban(playerid, params[])
{
	new name[MAX_PLAYER_NAME], query[128];
	if(sscanf(params, "s[24]", name)) return SendClientMessage(playerid, -1, "/unban <Name>");

	mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM `bans` WHERE `ban_name` = '%e' LIMIT 1", name);
	mysql_tquery(g_SQL, query, "BanUnban", "is", playerid, name);
	return 1;
}

forward BanUnban(playerid, user[]);
public BanUnban(playerid, user[])
{
	switch(cache_num_rows())
	{
	    case 0: SendClientMessage(playerid, -1, "There is no ban issued under the given username!");
	    case 1:
	    {
	        new query[128];
	        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM `bans` WHERE `ban_name` = '%e'", user);
	        mysql_tquery(g_SQL, query);

	        format(query, sizeof(query), "Administrator has unbanned %s!", user);
			SendClientMessageToAll(-1, query);
	        SendClientMessage(playerid, -1, "You've successfully unbanned the give username!");
	    }
	}
	return 1;
}

forward BanKontrol(playerid);
public BanKontrol(playerid)
{
	new namem[MAX_PLAYER_NAME];
	GetPlayerName(playerid, namem, MAX_PLAYER_NAME);
	switch(cache_num_rows())
	{
	    case 1:
	    {
			new time_left, admin[24], reason[30], str[256];
			cache_get_value_name(0, "ban_admin", admin, 24);
			cache_get_value_name(0, "ban_reason", reason, 30);
			cache_get_value_name_int(0, "ban_time", time_left);
			switch(time_left)
			{
			    case 0:
			    {
	   				format(str, sizeof(str),   "{FF0000}You are banned from the server!\n\
												{FFFFFF}Expire: {C3C3C3}Never (Permanent)\n\
				   								{FFFFFF}Admin: {C3C3C3}%s\n\
												{FFFFFF}Reason: {C3C3C3}%s", admin, reason);
	        		ShowPlayerDialog(playerid, DIALOG_BAN, DIALOG_STYLE_MSGBOX, "{FF0000}You are banned!", str, "Okay", "");
	        		Kick(playerid);
			    }
			    default:
			    {
				    if(gettime() > time_left)
				    {
				        SendClientMessage(playerid, -1, "{FF0000}Ban{FFFFFF}: Your ban has expired. You are now unbanned from the server.");
				        SendClientMessage(playerid, -1, "{FF0000}Ban{FFFFFF}: Please relog to proceed to the login screen.");
	   			    	mysql_format(g_SQL, str, sizeof(str), "DELETE FROM `bans` WHERE `ban_name` = '%e'", namem);
	   			    	mysql_tquery(g_SQL, str);
	   			    	Kick(playerid);
	   			    }else if(gettime() < time_left)
	   			    {
						new y, m, d, h, mi, s;
	   				    TimestampToDate(time_left, y, m, d, h, mi, s, 0, 0);
	   			    	format(str, sizeof(str),   "{FF0000}You are banned from the server!\n\
												  	{FFFFFF}Expire: {C3C3C3}%i/%i/%i [DD/MM/YY] | %i:%i\n\
													{FFFFFF}Admin: {C3C3C3}%s\n\
													{FFFFFF}Reason: {C3C3C3}%s", d, m, y, h, mi, admin, reason);
						ShowPlayerDialog(playerid, DIALOG_BAN, DIALOG_STYLE_MSGBOX, "{FF0000}You are banned!", str, "Bye Bye!", "");
						Kick(playerid);
					}
			    }
			}
		}
	}
	return 1;
}
