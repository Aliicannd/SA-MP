#include <a_samp>
#include <a_mysql>

#define MYSQL_HOST	"localhost"
#define MYSQL_USER	"root"
#define MYSQL_PASS 	"password"
#define MYSQL_DB	"database"

enum
{
    DIALOG_UNUSED,
    DIALOG_REGISTER,
    DIALOG_LOGIN
};
new MySQL: dbHandle;

enum e_Data
{
	UserID,
	Password[65],
	Salt[17],
	Name[MAX_PLAYER_NAME],
	Kills,
	Deaths,
	Money,
	Score,
	LoginAttempts,
	LoginTimer,
	bool:pLogged
}
new Player[MAX_PLAYERS][e_Data];

public OnFilterScriptInit()
{
	mysql_log(ALL);
	dbHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
	if(mysql_errno(dbHandle) != 0)
	{
		print("Could not connect to database!");
	}else
	{
		printf("Successfully connected on DB %s", MYSQL_DB);
	}
	mysql_tquery(dbHandle,  "CREATE TABLE IF NOT EXISTS `accounts` (\
														`UserID` INT(11) NOT NULL AUTO_INCREMENT,\
														`Username` VARCHAR(24) NOT NULL,\
														`Password` VARCHAR(129) NOT NULL,\
														`Salt` VARCHAR(16) NOT NULL,\
														`Kills` INT(11) NOT NULL,\
														`Deaths` INT(11) NOT NULL,\
														`Money` INT(11) NOT NULL,\
														`Score` INT(11) NOT NULL,\
														PRIMARY KEY (`UserID`))");
	return 1;
}
public OnFilterScriptExit()
{
	mysql_close(dbHandle);
	return 1;
}
public OnPlayerConnect(playerid)
{
	ResetPlayerMoney(playerid);
	for(new i; e_Data:i < e_Data; i++) Player[playerid][e_Data:i] = 0;

	GetPlayerName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);

	new query[128];
	mysql_format(dbHandle, query, sizeof(query),"SELECT * FROM `accounts` WHERE `Username` = '%e' LIMIT 1", Player[playerid][Name]);
	mysql_tquery(dbHandle, query, "OnAccountCheck", "i", playerid);
	return 1;
}

forward OnAccountCheck(playerid);
public OnAccountCheck(playerid)
{
	if(cache_num_rows())
	{
		cache_get_value_name(0, "Password", Player[playerid][Password], 129);
		cache_get_value_name(0, "Salt", Player[playerid][Salt], 17);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login", "In order to play, you need to login", "Login", "Quit");
		Player[playerid][LoginTimer] = SetTimerEx("OnLoginTimeout", 30 * 1000, false, "d", playerid);
	}else
	{
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "In order to play, you need to register.", "Register", "Quit");
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_UNUSED: return 1;
	    case DIALOG_LOGIN:
	    {
	        if(!response) return Kick(playerid);

			new hashed_pass[65], query[128];
			SHA256_PassHash(inputtext, Player[playerid][Salt], hashed_pass, 65);
			if(strcmp(hashed_pass, Player[playerid][Password]) == 0)
			{
				mysql_format(dbHandle, query, sizeof(query), "SELECT * FROM `accounts` WHERE `Username` = '%e' LIMIT 1", Player[playerid][Name]);
				mysql_tquery(dbHandle, query, "OnAccountLoad", "i", playerid);
				KillTimer(Player[playerid][LoginTimer]);
				Player[playerid][LoginTimer] = 0;
			}else
			{
				Player[playerid][LoginAttempts]++;
				if(Player[playerid][LoginAttempts] >= 3)
				{
					ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "You have mistyped your password too often (3 times).", "Okay", "");
					Kick(playerid);
					return 1;
				}
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login", "In order to play, you need to login\nWrong password!", "Login", "Quit");
			}
		}
		case DIALOG_REGISTER:
		{
		    if(!response) return Kick(playerid);

		    if(strlen(inputtext) < 6) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "In order to play, you need to register.\nYour password must be at least 6 characters long!", "Register", "Quit");
			for (new i = 0; i < 16; i++) Player[playerid][Salt][i] = random(94) + 33;
			SHA256_PassHash(inputtext, Player[playerid][Salt], Player[playerid][Password], 65);

			new query[256];
			mysql_format(dbHandle, query, sizeof(query), "INSERT INTO `accounts` (`Username`, `Password`, `Salt`) VALUES ('%e', '%s', '%e')", Player[playerid][Name], Player[playerid][Password], Player[playerid][Salt]);
			mysql_tquery(dbHandle, query, "OnAccountRegister", "i", playerid);
		}
		default: return 0;
	}
	return 1;
}

forward OnAccountLoad(playerid);
public OnAccountLoad(playerid)
{
    cache_get_value_name_int(0, "UserID", Player[playerid][UserID]);
	cache_get_value_name_int(0, "Kills", Player[playerid][Kills]);
	cache_get_value_name_int(0, "Deaths", Player[playerid][Deaths]);
	cache_get_value_name_int(0, "Money", Player[playerid][Money]);
	cache_get_value_name_int(0, "Score", Player[playerid][Score]);

 	SetPlayerScore(playerid, Player[playerid][Score]);
 	GivePlayerMoney(playerid, Player[playerid][Money]);
	Player[playerid][pLogged] = true;
	SendClientMessage(playerid, -1, "Successfully logged in");
	return 1;
}

forward OnAccountRegister(playerid);
public OnAccountRegister(playerid)
{
    Player[playerid][UserID] = cache_insert_id();
    GivePlayerMoney(playerid, 50000);
    Player[playerid][pLogged] = true;
    printf("New account registered. ID: %d", Player[playerid][UserID]);
    return 1;
}
forward OnLoginTimeout(playerid);
public OnLoginTimeout(playerid)
{
	Player[playerid][LoginTimer] = 0;

	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "You have been kicked for taking too long to login successfully to your account.", "Okay", "");
	Kick(playerid);
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	UpdatePlayerData(playerid);
	if(Player[playerid][LoginTimer])
	{
		KillTimer(Player[playerid][LoginTimer]);
		Player[playerid][LoginTimer] = 0;
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID)
	{
		Player[killerid][Kills]++;
	}
	Player[playerid][Deaths]++;
	return 1;
}

stock UpdatePlayerData(playerid)
{
    if(Player[playerid][pLogged] == true)
	{
		new query[256];
		mysql_format(dbHandle, query, sizeof(query), "UPDATE `accounts` SET `Kills` = %d, `Deaths` = %d, `Money` = %d, `Score` = %d WHERE `ID` = %d", Player[playerid][Kills], Player[playerid][Deaths], GetPlayerMoney(playerid), GetPlayerScore(playerid), Player[playerid][UserID]);
		mysql_tquery(dbHandle, query);
	}
	return 1;
}
