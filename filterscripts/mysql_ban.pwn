/*
	MySQL Ban system created by Gammix
*/
#define FILTERSCRIPT
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <zcmd>
#include <timestamp>

#define MYSQL_HOST		"localhost"
#define MYSQL_USER		"root"
#define MYSQL_PASS		""
#define MYSQL_DATABASE	"bancik"

#define MAX_BAN_REASON_LENGTH 64 // max string length of ban reason
#define KICK_TIMER_DELAY 150 // in miliseconds - a timer delay added to Kick(); function

#define CIDR_BAN_MASK (-1<<(32-(26))) // 26 = this is the CIDR ip detection range

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_TOMATO 0xFF6347FF

#define COL_WHITE "{FFFFFF}"
#define COL_TOMATO "{FF6347}"
#define COL_GREY "{c4c4c4}"

#define MAX_PLAYER_IP 18

#define DIALOG_UNUSED 457

new MySQL:BanHandle;

IpToLong(const address[])
{
	new parts[4];
	sscanf(address, "p<.>a<i>[4]", parts);
	return ((parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]);
}

ReturnDate(timestamp)
{
	static const MONTH_NAMES[12][] =
	{
		"January", "Feburary", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
	};

	new year, month, day, hour, minute, second;
	stamp2datetime(timestamp, year, month, day, hour, minute, second);

	new ret[32];
	format(ret, sizeof(ret), "%i %s, %i", day, MONTH_NAMES[month - 1], year);
	return ret;
}

ReturnTimelapse(start, till)
{
	new ret[32];
	new seconds = (till - start);

	const
		MINUTE = (60),
		HOUR = (60 * MINUTE),
		DAY = (24 * HOUR),
		MONTH = (30 * DAY);

	if (seconds == 1) {
		format(ret, sizeof(ret), "a second");
	} else if (seconds < (1 * MINUTE)) {
		format(ret, sizeof(ret), "%i seconds", seconds);
	} else if (seconds < (2 * MINUTE)) {
		format(ret, sizeof(ret), "a minute");
	} else if (seconds < (45 * MINUTE)) {
		format(ret, sizeof(ret), "%i minutes", (seconds / MINUTE));
	} else if (seconds < (90 * MINUTE)) {
		format(ret, sizeof(ret), "an hour");
	} else if (seconds < (24 * HOUR)) {
		format(ret, sizeof(ret), "%i hours", (seconds / HOUR));
	} else if (seconds < (48 * HOUR)) {
		format(ret, sizeof(ret), "a day");
	} else if (seconds < (30 * DAY)) {
		format(ret, sizeof(ret), "%i days", (seconds / DAY));
	} else if (seconds < (12 * MONTH)) {
		new months = floatround(seconds / DAY / 30);
      	if (months <= 1) {
			format(ret, sizeof(ret), "a month");
      	} else {
			format(ret, sizeof(ret), "%i months", months);
		}
	} else {
      	new years = floatround(seconds / DAY / 365);
      	if (years <= 1) {
			format(ret, sizeof(ret), "a year");
      	} else {
			format(ret, sizeof(ret), "%i years", years);
		}
	}
	return ret;
}

forward DelayKick(playerid);
public DelayKick(playerid) return Kick(playerid);

public OnFilterScriptInit()
{
	mysql_log(ALL);
	print("[mysql_ban.pwn] Connecting to MySQL server....");
	BanHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE);
	if (mysql_errno(BanHandle) != 0)
	{
		print("[mysql_ban.pwn] Connection error!");
		return SendRconCommand("exit");
	}else
	{
		print("[mysql_ban.pwn] Connection successfull!");
	}

	mysql_tquery(BanHandle, "CREATE TABLE IF NOT EXISTS bans (\
														id INT(11) NOT NULL AUTO_INCREMENT, \
														name VARCHAR(24) DEFAULT NULL, \
														ip VARCHAR(24) DEFAULT NULL, \
														longip INT DEFAULT NULL, \
														ban_timestamp INT DEFAULT NULL, \
														ban_expire_timestamp INT DEFAULT NULL, \
														ban_admin VARCHAR(24) DEFAULT NULL, \
														ban_reason VARCHAR("#MAX_BAN_REASON_LENGTH") DEFAULT NULL, \
														PRIMARY KEY(id))");
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(BanHandle);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new name[MAX_PLAYER_NAME], ip[MAX_PLAYER_IP];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, ip, MAX_PLAYER_IP);

	new string[MAX_PLAYER_NAME + 256];
	mysql_format(BanHandle, string, sizeof(string), "SELECT * FROM bans WHERE (name = '%e') OR (ip = '%e') OR (longip & %i = %i) LIMIT 1", name, ip, CIDR_BAN_MASK, (IpToLong(ip) & CIDR_BAN_MASK));
	mysql_tquery(BanHandle, string, "OnUserBanDataLoad", "i", playerid);
	return 1;
}

forward OnUserBanDataLoad(playerid);
public OnUserBanDataLoad(playerid)
{
	if(cache_num_rows() == 1)
	{
		new string[144], ban_id, ban_expire_timestamp;
		cache_get_value_name_int(0, "id", ban_id);
		cache_get_value_name_int(0, "ban_expire_timestamp", ban_expire_timestamp);

		if(ban_expire_timestamp != 0 && gettime() >= ban_expire_timestamp)
		{
			mysql_format(BanHandle, string, sizeof(string), "DELETE FROM bans WHERE id = %i", ban_id);
			mysql_tquery(BanHandle, string);
			return 1;
		}
		new ban_timestamp, ban_admin[MAX_PLAYER_NAME], ban_reason[MAX_BAN_REASON_LENGTH];

		cache_get_value_name_int(0, "ban_timestamp", ban_timestamp);
		cache_get_value_name(0, "ban_admin", ban_admin, sizeof(ban_admin));
		cache_get_value_name(0, "ban_reason", ban_reason, sizeof(ban_reason));

		for (new i = 0; i < 20; i++) SendClientMessage(playerid, COLOR_TOMATO, "");

		format(string, sizeof(string), "This account is banned on this server! Banned on %s (%s ago) by admin %s!", ReturnDate(ban_timestamp), ReturnTimelapse(ban_timestamp, gettime()), ban_admin);
		SendClientMessage(playerid, COLOR_TOMATO, string);
		format(string, sizeof(string), "Reason: %s", ban_reason);
		SendClientMessage(playerid, COLOR_TOMATO, string);
		if(ban_expire_timestamp != 0)
		{
			format(string, sizeof(string), "Your ban will be lifted on: %s (%s)", ReturnDate(ban_expire_timestamp), ReturnTimelapse(gettime(), ban_expire_timestamp));
			SendClientMessage(playerid, COLOR_TOMATO, string);
		}
		SetTimerEx("DelayKick", KICK_TIMER_DELAY, false, "i", playerid);
	}
	return 1;
}

CMD:ban(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_TOMATO, "You should be RCON Admin to use this command.");
	new targetid, days, reason[MAX_BAN_REASON_LENGTH];
	
	if(sscanf(params, "uis["#MAX_BAN_REASON_LENGTH"]", targetid, days, reason))
	{
		SendClientMessage(playerid, COLOR_WHITE, "Usage: /ban [id/name] [days] [reason]");
		SendClientMessage(playerid, COLOR_WHITE, "Note: 0 days means a permanent ban from server.");
		return 1;
	}
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_TOMATO, "Error: Target player isn't online.");
	if(days < 0 || days > 365) return SendClientMessage(playerid, COLOR_TOMATO, "Error: Number of days cannot be negative or greater than 365 days! [0 = permanent ban]");
	if(strlen(reason) < 4) return SendClientMessage(playerid, COLOR_TOMATO, "Error: Invalid reason entered.");
	
	new name[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME], targetip[MAX_PLAYER_IP];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerName(targetid, targetname, MAX_PLAYER_NAME);
	GetPlayerIp(targetid, targetip, MAX_PLAYER_IP);
	
	new ban_expire_timestamp = (days == 0) ? (0) : (gettime() + (days * 86400));

	new string[1024];
	mysql_format(BanHandle, string, sizeof(string), "INSERT INTO bans(name, ip, longip, ban_timestamp, ban_expire_timestamp, ban_admin, ban_reason) VALUES ('%e', '%e', %i, %i, %i, '%e', '%e')", targetname, targetip, IpToLong(targetip), gettime(), ban_expire_timestamp, name, reason);
	mysql_tquery(BanHandle, string);

	if(days != 0)
	{
		format(string, sizeof(string), "* Admin %s has banned %s for %i days (will be unbanned on %s) || Today's Date: %s || Reason: %s", name, targetname, days,  ReturnDate(ban_expire_timestamp), ReturnDate(gettime()), reason);
	}else
	{
		format(string, sizeof(string), "* Admin %s has banned %s permanently || Today's Date: %s || Reason: %s", name, targetname, ReturnDate(gettime()), reason);
	}
	SendClientMessageToAll(COLOR_TOMATO, string);

	for (new i = 0; i < 100; i++) SendClientMessage(targetid, COLOR_TOMATO, "");

	format(string, sizeof(string), "Your account has been banned on this server, by admin %s! [Today's Date: %s]", name, ReturnDate(gettime()));
	SendClientMessage(targetid, COLOR_TOMATO, string);
	format(string, sizeof(string), "Reason: %s", reason);
	SendClientMessage(targetid, COLOR_TOMATO, string);
	if(ban_expire_timestamp != 0)
	{
		format(string, sizeof(string), "Your ban will be lifted on: %s (%s later)", ReturnDate(ban_expire_timestamp), ReturnTimelapse(gettime(), ban_expire_timestamp));
		SendClientMessage(targetid, COLOR_TOMATO, string);
	}
	SetTimerEx("DelayKick", KICK_TIMER_DELAY, false, "i", targetid);
	return 1;
}

CMD:findban(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_TOMATO, "You should be RCON Admin to use this command.");
	new match[32];
	if (sscanf(params, "s[32]", match)) return SendClientMessage(playerid, COLOR_WHITE, "Usage: /unban [name/ip]");

	new string[MAX_PLAYER_NAME + 256];
	mysql_format(BanHandle, string, sizeof(string), "SELECT * FROM bans WHERE (name = '%e') OR (ip = '%e') OR (longip & %i = %i) LIMIT 1", match, match, CIDR_BAN_MASK, (IpToLong(match) & CIDR_BAN_MASK));
	mysql_tquery(BanHandle, string, "OnFindBanSearchDataLoad", "is", playerid, match);
	return 1;
}

forward OnFindBanSearchDataLoad(playerid, const match[]);
public OnFindBanSearchDataLoad(playerid, const match[])
{
	if (cache_num_rows() == 0) return SendClientMessage(playerid, COLOR_TOMATO, "Error: User not found in ban database!");

	new string[512], ban_id, ban_expire_timestamp;
	cache_get_value_name_int(0, "id", ban_id);
	cache_get_value_name_int(0, "ban_expire_timestamp", ban_expire_timestamp);

	if(ban_expire_timestamp != 0 && gettime() >= ban_expire_timestamp)
	{
		mysql_format(BanHandle, string, sizeof(string), "DELETE FROM bans WHERE id = %i",ban_id);
		mysql_tquery(BanHandle, string);
		return SendClientMessage(playerid, COLOR_TOMATO, "Error: User not found in ban database!");
	}

	new name[MAX_PLAYER_NAME], ip[MAX_PLAYER_IP], date, unban_date, admin[MAX_PLAYER_NAME], reason[MAX_BAN_REASON_LENGTH];

	cache_get_value_name(0, "name", name, MAX_PLAYER_NAME);
	cache_get_value_name(0, "ip", ip, MAX_PLAYER_IP);
	cache_get_value_name_int(0, "ban_timestamp", date);
	cache_get_value_name_int(0, "ban_expire_timestamp", unban_date);
	cache_get_value_name(0, "ban_admin", admin, MAX_PLAYER_NAME);
	cache_get_value_name(0, "ban_reason", reason, MAX_BAN_REASON_LENGTH);

	if(unban_date == 0)
	{
		format(string, sizeof(string), ""COL_GREY"UserName: "COL_TOMATO"%s\n\
										"COL_GREY"IP Address: "COL_TOMATO"%s\n\
										"COL_GREY"Banned By Admin: "COL_WHITE"%s\n\
										"COL_GREY"Banned On Date: "COL_WHITE"%s (%s ago)\n\
										"COL_GREY"Ban Type: "COL_WHITE"Permanent\n\
										"COL_GREY"Reason: "COL_WHITE"%s\n\n\
										Today's Date: %s!\n\
										To unban a player, type /unban <name/ip>!",
										name, ip, admin, ReturnDate(date), ReturnTimelapse(date, gettime()), reason, ReturnDate(gettime()));
	}else
	{
		format(string, sizeof(string), ""COL_GREY"UserName: "COL_TOMATO"%s\n\
										"COL_GREY"IP Address: "COL_TOMATO"%s\n\
										"COL_GREY"Banned By Admin: "COL_WHITE"%s\n\
										"COL_GREY"Banned On Date: "COL_WHITE"%s (%s ago)\n\
										"COL_GREY"UnBan On: "COL_TOMATO"%s (%s)\n\
										"COL_GREY"Reason: "COL_WHITE"%s\n\n\
										Today's Date: %s!\n\
										To unban a player, type /unban <name/ip>!",
									 	name, ip, admin, ReturnDate(date), ReturnTimelapse(date, gettime()), ReturnDate(unban_date), ReturnTimelapse(gettime(), unban_date), reason, ReturnDate(gettime()));
	}
	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Ban Info", string, "Close", "");
	return 1;
}

CMD:unban(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_TOMATO, "You should be RCON Admin to use this command.");
	new match[32];
	if(sscanf(params, "s[32]", match)) return SendClientMessage(playerid, COLOR_WHITE, "Usage: /unban [name/ip]");

	new string[MAX_PLAYER_NAME + 256];
	mysql_format(BanHandle, string, sizeof(string), "SELECT * FROM bans WHERE (name = '%e') OR (ip = '%e') OR (longip & %i = %i) LIMIT 1", match, match, CIDR_BAN_MASK, (IpToLong(match) & CIDR_BAN_MASK));
	mysql_tquery(BanHandle, string, "OnUnBanSearchDataLoad", "i", playerid);
	return 1;
}

forward OnUnBanSearchDataLoad(playerid);
public OnUnBanSearchDataLoad(playerid)
{
	if (cache_num_rows() == 0) return SendClientMessage(playerid, COLOR_TOMATO, "Error: User not found in ban database!");
    
	new string[144], ban_expire_timestamp, ban_id;
	cache_get_value_name_int(0, "id", ban_id);
	cache_get_value_name_int(0, "ban_expire_timestamp", ban_expire_timestamp);

	if(ban_expire_timestamp != 0 && gettime() >= ban_expire_timestamp)
	{
		mysql_format(BanHandle, string, sizeof(string), "DELETE FROM bans WHERE id = %i", ban_id);
		mysql_tquery(BanHandle, string);
		SendClientMessage(playerid, COLOR_TOMATO, "Error: User not found in ban database!");
		return 1;
	}

	new admin[MAX_PLAYER_NAME], target[MAX_PLAYER_NAME];
	cache_get_value_name(0, "name", target, MAX_PLAYER_NAME);

	GetPlayerName(playerid, admin, MAX_PLAYER_NAME);

	mysql_format(BanHandle, string, sizeof(string), "DELETE FROM bans WHERE id = %i", ban_id);
	mysql_tquery(BanHandle, string);

	format(string, sizeof(string), "* Admin %s has unbanned %s || Today's Date: %s", admin, target, ReturnDate(gettime()));
	SendClientMessageToAll(COLOR_TOMATO, string);
	return 1;
}
