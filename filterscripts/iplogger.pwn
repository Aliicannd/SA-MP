/*
			iplogger by itsToretto(https://github.com/itsToretto)

			Topic: https://forum.sa-mp.com/showthread.php?t=660401
				   https://www.burgershot.gg/showthread.php?tid=443
*/

#define FILTERSCRIPT
#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <zcmd>

#define MYSQL_HOSTNAME		"localhost"
#define MYSQL_USERNAME		"root"
#define MYSQL_PASSWORD		""
#define MYSQL_DATABASE		"test"

new MySQL: Database;

enum
{
    DIALOG_IPINDEX = 369,
    DIALOG_IPLOGS,
    DIALOG_IPACTION,
    DIALOG_IPDELETION
}

new g_ConnectionDate[MAX_PLAYERS],
    g_pIP[MAX_PLAYERS][16],
    g_Name[MAX_PLAYERS][MAX_PLAYER_NAME],
    g_DialogPage[MAX_PLAYERS],
    g_Target[MAX_PLAYERS][MAX_PLAYER_NAME];

public OnFilterScriptInit()
{
    mysql_global_options(DUPLICATE_CONNECTIONS, true);
    Database = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);
    if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0) return print("[iplogger] MySQL connection failed.");
    mysql_tquery(Database,
        "CREATE TABLE IF NOT EXISTS `iplogger` ( \
           `Name` varchar(24) NOT NULL, \
           `IP` int(10) unsigned NOT NULL, \
           `Connected` datetime NOT NULL, \
           `Disconnected` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP, \
          PRIMARY KEY (`Name`,`Connected`) \
         ) ENGINE=InnoDB DEFAULT CHARSET=latin1");
    return 1;
}

ShowIpLogsDialog(playerid)
{
    new query[181];
    mysql_format(Database, query, sizeof(query), "SELECT INET_NTOA(`IP`) AS `IP`, DATE_FORMAT(`Connected`, '%%Y %%M %%e - %%T') AS `Connected` FROM `iplogger` WHERE `Name` = '%e' ORDER BY `Connected` DESC LIMIT %d, 10", g_Target[playerid], g_DialogPage[playerid] * 10);
    mysql_tquery(Database, query, "OnIpLogsDisplay", "d", playerid);
    return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerIp(playerid, g_pIP[playerid], 16);
    GetPlayerName(playerid, g_Name[playerid], MAX_PLAYER_NAME);
    g_ConnectionDate[playerid] = gettime();
    g_DialogPage[playerid] = 0;
    g_Target[playerid][0] = '\0';
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new query[137];
    mysql_format(Database, query, sizeof(query), "INSERT INTO `iplogger` (`Name`, `IP`, `Connected`) VALUES ('%s', INET_ATON('%s'), FROM_UNIXTIME(%d))", g_Name[playerid], g_pIP[playerid], g_ConnectionDate[playerid]);
    mysql_tquery(Database, query);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_IPINDEX:
        {
            if(response)
            {
                if(sscanf(inputtext, "s[24]", g_Target[playerid])) return 1;
                new query[74];
                mysql_format(Database, query, sizeof(query), "SELECT COUNT(*) FROM `iplogger` WHERE `Name` = '%e'", g_Target[playerid]);
                mysql_tquery(Database, query, "OnIpLogsManage", "d", playerid);
            }
        }
        case DIALOG_IPLOGS:
        {
            if(!response)
            {
                g_DialogPage[playerid]--;
                if(g_DialogPage[playerid] < 0)
                {
                    g_DialogPage[playerid] = 0;
                    ShowPlayerDialog(playerid, DIALOG_IPINDEX, DIALOG_STYLE_INPUT, "IP Logger - Index", "{FFFFFF}Enter the player's full name below:", "Submit", "Cancel");
                    return 1;
                }
            }else
                g_DialogPage[playerid]++;

            ShowIpLogsDialog(playerid);
            return 1;
        }
        case DIALOG_IPACTION:
        {
            if(response)
            {
                switch(listitem)
                {
                    case 0: ShowIpLogsDialog(playerid);
                    case 1:
                    {
                        new dialog[159];
                        format(dialog, sizeof(dialog), "{FFFFFF}Are you sure you want to {DE3838}delete {2ECC71}%s{FFFFFF}'s IP Logs permanently?\n(This action is {DE3838}irreversible{FFFFFF})", g_Target[playerid]);
                        ShowPlayerDialog(playerid, DIALOG_IPDELETION, DIALOG_STYLE_MSGBOX, "Confirmation:", dialog, "Delete", "Cancel");
                    }
                }
            }else
                ShowPlayerDialog(playerid, DIALOG_IPINDEX, DIALOG_STYLE_INPUT, "IP Logger - Index", "{FFFFFF}Enter the player's full name below:", "Submit", "Cancel");
        }
        case DIALOG_IPDELETION:
        {
            if(response)
            {
                new query[59];
                mysql_format(Database, query, sizeof(query), "DELETE FROM `iplogger` WHERE `Name` = '%e'", g_Target[playerid]);
                mysql_tquery(Database, query, "OnIpLogsDelete", "d", playerid);
            }else
                SendClientMessage(playerid, 0x33CCFFFF, "INFO: {FFFFFF}You have canceled the logs deletion.");
        }
        default: return 0;
    }
    return 1;
}

forward OnIpLogsDisplay(playerid);
public OnIpLogsDisplay(playerid)
{
    new rows = cache_num_rows();
    if(rows)
    {
        new title[56], string[103], dialog[sizeof string * 10], sql_ip[16], sql_connected[29];
        for(new i; i < rows; i++)
        {
            cache_get_value_name(i, "IP", sql_ip);
            cache_get_value_name(i, "Connected", sql_connected);
            format(string, sizeof(string), "{2ECC71}IP: {FFFFFF}%s{2ECC71} - Last connection: {FFFFFF}%s\n", sql_ip, sql_connected);
            strcat(dialog, string);
        }
        format(title, sizeof(title), "IP Logs of {2ECC71}%s (Page %d)", g_Target[playerid], g_DialogPage[playerid]+1);
        ShowPlayerDialog(playerid, DIALOG_IPLOGS, DIALOG_STYLE_LIST, title, dialog, "{FFFFFF}Next", "Back");
    }else
    {
        if(g_DialogPage[playerid] > 0)
        {
            g_DialogPage[playerid] = 0;
            return SendClientMessage(playerid, 0x33CCFFFF, "INFO: {FFFFFF}Can't find any more IP Logs records.");
        }
    }
    return 1;
}

forward OnIpLogsManage(playerid);
public OnIpLogsManage(playerid)
{
    if(!cache_num_rows()) return SendClientMessage(playerid, 0xDE3838FF, "ERROR: {FFFFFF}Player not found.");

    new title[65], dialog[155];
    format(title, sizeof(title), "IP Logs Panel - Managing player {2ECC71}%s", g_Target[playerid]);
    format(dialog, sizeof(dialog), "  {FFFF00}> {FFFFFF}Show {2ECC71}%s{FFFFFF}'s IP Logs\n  {FFFF00}> {DE3838}Delete {2ECC71}%s{DE3838}'s IP Logs", g_Target[playerid], g_Target[playerid]);
    ShowPlayerDialog(playerid, DIALOG_IPACTION, DIALOG_STYLE_LIST, title, dialog, "Submit", "Cancel");
    return 1;
}

forward OnIpLogsDelete(playerid);
public OnIpLogsDelete(playerid)
{
    if(cache_affected_rows())
    {
        new string[101];
        format(string, sizeof(string), "INFO: {FFFFFF}You have successfully {DE3838}deleted {AFAFAF}%s{FFFFFF}'s logs.", g_Target[playerid]);
        SendClientMessage(playerid, 0x33CCFFFF, string);
    }
}

CMD:iplogger(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_IPINDEX, DIALOG_STYLE_INPUT, "IP Logger - Index", "{FFFFFF}Enter the player's full name below:", "Submit", "Cancel");
    return 1;
}
