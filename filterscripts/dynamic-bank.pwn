/*
	Yet Another Banking System by rootcause

	MySQL R40 Version
	Topic: http://forum.sa-mp.com/showthread.php?t=606450
*/

#define 	FILTERSCRIPT
#include 	<a_samp>
#include    <a_mysql>           // by BlueG & maddinat0r - http://forum.sa-mp.com/showthread.php?t=56564
#include    <izcmd>             // by Yashas - http://forum.sa-mp.com/showthread.php?t=576114
#include    <sscanf2>           // by Y_Less - http://forum.sa-mp.com/showthread.php?t=602923
#include    <streamer>          // by Incognito - http://forum.sa-mp.com/showthread.php?t=102865
#include    <WeaponData>    	// by Southclaw - https://github.com/Southclaw/AdvancedWeaponData
#include    <YSI\y_iterate>     // by Y_Less - http://forum.sa-mp.com/showthread.php?t=570884

#define     MYSQL_HOST      "host"
#define     MYSQL_USER      "user"
#define     MYSQL_PASS      "password"
#define     MYSQL_DBNAME    "dbname"

#define     MAX_BANKERS     (20)
#define     MAX_ATMS        (100)

#define     BANKER_USE_MAPICON      			// comment or remove this line if you don't want bankers to have mapicons
#define     ATM_USE_MAPICON         			// comment or remove this line if you don't want atms to have mapicons
#define     BANKER_ICON_RANGE       (10.0)		// banker mapicon stream distance, you can remove this if you're not using banker icons (default: 10.0)
#define     ATM_ICON_RANGE       	(100.0)		// atm mapicon stream distance, you can remove this if you're not using banker icons (default: 100.0)
#define     ACCOUNT_PRICE           (100)      	// amount of money required to create a new bank account (default: 100)
#define     ACCOUNT_CLIMIT          (5)         // a player can create x accounts, you can comment or remove this line if you don't want an account limit (default: 5)
#define     ACCOUNT_LIMIT           (500000000) // how much money can a bank account have (default: 500,000,000)

// ATM Robbery Config
//#define     ROBBABLE_ATMS           // uncomment this line if you want robbable atms

#if defined ROBBABLE_ATMS
	#define     ATM_HEALTH              (350.0)     // health of an atm (Default: 350.0)
	#define     ATM_REGEN               (120)       // a robbed atm will start working after x seconds (Default: 120)
	#define     ATM_ROB_MIN  			(1500)   	// min. amount of money stolen from an atm (Default: 1500)
	#define     ATM_ROB_MAX  			(3500)  	// max. amount of money stolen from an atm (Default: 3500)
#endif

enum    _:E_BANK_DIALOG
{
    DIALOG_BANK_MENU_NOLOGIN = 12450,
    DIALOG_BANK_MENU,
    DIALOG_BANK_CREATE_ACCOUNT,
    DIALOG_BANK_ACCOUNTS,
    DIALOG_BANK_LOGIN_ID,
	DIALOG_BANK_LOGIN_PASS,
	DIALOG_BANK_DEPOSIT,
	DIALOG_BANK_WITHDRAW,
	DIALOG_BANK_TRANSFER_1,
	DIALOG_BANK_TRANSFER_2,
	DIALOG_BANK_PASSWORD,
	DIALOG_BANK_REMOVE,
	DIALOG_BANK_LOGS,
	DIALOG_BANK_LOG_PAGE
}

enum    _:E_BANK_LOGTYPE
{
	TYPE_NONE,
	TYPE_LOGIN,
	TYPE_DEPOSIT,
	TYPE_WITHDRAW,
	TYPE_TRANSFER,
	TYPE_PASSCHANGE
}

#if defined ROBBABLE_ATMS
enum    _:E_ATMDATA
{
	IDString[8],
	refID
}
#endif

enum    E_BANKER
{
	// saved
	Skin,
	Float: bankerX,
	Float: bankerY,
	Float: bankerZ,
	Float: bankerA,
	// temp
	bankerActorID,
	#if defined BANKER_USE_MAPICON
	bankerIconID,
	#endif
	Text3D: bankerLabel
}

enum    E_ATM
{
	// saved
	Float: atmX,
	Float: atmY,
	Float: atmZ,
	Float: atmRX,
	Float: atmRY,
	Float: atmRZ,
	// temp
	atmObjID,
	
	#if defined ATM_USE_MAPICON
	atmIconID,
	#endif
	
	#if defined ROBBABLE_ATMS
	Float: atmHealth,
	atmRegen,
	atmTimer,
	atmPickup,
	#endif
	
	Text3D: atmLabel
}

new
	MySQL: BankSQLHandle;

new
	BankerData[MAX_BANKERS][E_BANKER],
	ATMData[MAX_ATMS][E_ATM];

new
	Iterator: Bankers<MAX_BANKERS>,
	Iterator: ATMs<MAX_ATMS>;

new
	CurrentAccountID[MAX_PLAYERS] = {-1, ...},
	LogListType[MAX_PLAYERS] = {TYPE_NONE, ...},
	LogListPage[MAX_PLAYERS],
	EditingATMID[MAX_PLAYERS] = {-1, ...};

formatInt(intVariable, iThousandSeparator = ',', iCurrencyChar = '$')
{
    /*
		By Kar
		https://gist.github.com/Kar2k/bfb0eafb2caf71a1237b349684e091b9/8849dad7baa863afb1048f40badd103567c005a5#file-formatint-function
	*/
	static
		s_szReturn[ 32 ],
		s_szThousandSeparator[ 2 ] = { ' ', EOS },
		s_szCurrencyChar[ 2 ] = { ' ', EOS },
		s_iVariableLen,
		s_iChar,
		s_iSepPos,
		bool:s_isNegative
	;

	format( s_szReturn, sizeof( s_szReturn ), "%d", intVariable );

	if(s_szReturn[0] == '-')
		s_isNegative = true;
	else
		s_isNegative = false;

	s_iVariableLen = strlen( s_szReturn );

	if ( s_iVariableLen >= 4 && iThousandSeparator)
	{
		s_szThousandSeparator[ 0 ] = iThousandSeparator;

		s_iChar = s_iVariableLen;
		s_iSepPos = 0;

		while ( --s_iChar > _:s_isNegative )
		{
			if ( ++s_iSepPos == 3 )
			{
				strins( s_szReturn, s_szThousandSeparator, s_iChar );

				s_iSepPos = 0;
			}
		}
	}
	if(iCurrencyChar) {
		s_szCurrencyChar[ 0 ] = iCurrencyChar;
		strins( s_szReturn, s_szCurrencyChar, _:s_isNegative );
	}
	return s_szReturn;
}

#if defined ROBBABLE_ATMS
RandomEx(min, max) //Y_Less
    return random(max - min) + min;

ConvertToMinutes(time)
{
    // http://forum.sa-mp.com/showpost.php?p=3223897&postcount=11
    new string[15];//-2000000000:00 could happen, so make the string 15 chars to avoid any errors
    format(string, sizeof(string), "%02d:%02d", time / 60, time % 60);
    return string;
}
#endif

IsPlayerNearBanker(playerid)
{
	foreach(new i : Bankers)
	{
	    if(IsPlayerInRangeOfPoint(playerid, 3.0, BankerData[i][bankerX], BankerData[i][bankerY], BankerData[i][bankerZ])) return 1;
	}

	return 0;
}

GetClosestATM(playerid, Float: range = 3.0)
{
	new id = -1, Float: dist = range, Float: tempdist;
	foreach(new i : ATMs)
	{
	    tempdist = GetPlayerDistanceFromPoint(playerid, ATMData[i][atmX], ATMData[i][atmY], ATMData[i][atmZ]);

	    if(tempdist > range) continue;
		if(tempdist <= dist)
		{
			dist = tempdist;
			id = i;
		}
	}

	return id;
}

Bank_SaveLog(playerid, type, accid, toaccid, amount)
{
	if(type == TYPE_NONE) return 1;
	new query[256];

	switch(type)
	{
	    case TYPE_LOGIN, TYPE_PASSCHANGE: mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bank_logs SET AccountID=%d, Type=%d, Player='%e', Date=UNIX_TIMESTAMP()", accid, type, Player_GetName(playerid));
	    case TYPE_DEPOSIT, TYPE_WITHDRAW: mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bank_logs SET AccountID=%d, Type=%d, Player='%e', Amount=%d, Date=UNIX_TIMESTAMP()", accid, type, Player_GetName(playerid), amount);
		case TYPE_TRANSFER: mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bank_logs SET AccountID=%d, ToAccountID=%d, Type=%d, Player='%e', Amount=%d, Date=UNIX_TIMESTAMP()", accid, toaccid, type, Player_GetName(playerid), amount);
	}

	mysql_tquery(BankSQLHandle, query);
	return 1;
}

Bank_ShowMenu(playerid)
{
	new string[256], using_atm = GetPVarInt(playerid, "usingATM");
	if(CurrentAccountID[playerid] == -1) {
		format(string, sizeof(string), "{%06x}Create Account\t{2ECC71}%s\nMy Accounts\t{F1C40F}%d\nAccount Login", (using_atm ? 0xE74C3CFF >>> 8 : 0xFFFFFFFF >>> 8), (using_atm ? ("") : formatInt(ACCOUNT_PRICE)), Bank_AccountCount(playerid));
		ShowPlayerDialog(playerid, DIALOG_BANK_MENU_NOLOGIN, DIALOG_STYLE_TABLIST, "{F1C40F}Bank: {FFFFFF}Menu", string, "Choose", "Close");
	}else{
	    new balance = Bank_GetBalance(CurrentAccountID[playerid]), menu_title[64];
		format(menu_title, sizeof(menu_title), "{F1C40F}Bank: {FFFFFF}Menu (Account ID: {F1C40F}%d{FFFFFF})", CurrentAccountID[playerid]);

	    format(
			string,
			sizeof(string),
			"{%06x}Create Account\t{2ECC71}%s\nMy Accounts\t{F1C40F}%d\nDeposit\t{2ECC71}%s\nWithdraw\t{2ECC71}%s\nTransfer\t{2ECC71}%s\n{%06x}Account Logs\n{%06x}Change Password\n{%06x}Remove Account\nLogout",
			(using_atm ? 0xE74C3CFF >>> 8 : 0xFFFFFFFF >>> 8),
			(using_atm ? ("") : formatInt(ACCOUNT_PRICE)),
			Bank_AccountCount(playerid),
			formatInt(GetPlayerMoney(playerid)),
			formatInt(balance),
			formatInt(balance),
			(using_atm ? 0xE74C3CFF >>> 8 : 0xFFFFFFFF >>> 8),
			(using_atm ? 0xE74C3CFF >>> 8 : 0xFFFFFFFF >>> 8),
			(using_atm ? 0xE74C3CFF >>> 8 : 0xFFFFFFFF >>> 8)
		);

		ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_TABLIST, menu_title, string, "Choose", "Close");
	}

	DeletePVar(playerid, "bankLoginAccount");
	DeletePVar(playerid, "bankTransferAccount");
	return 1;
}

Bank_ShowLogMenu(playerid)
{
	LogListType[playerid] = TYPE_NONE;
	LogListPage[playerid] = 0;
	ShowPlayerDialog(playerid, DIALOG_BANK_LOGS, DIALOG_STYLE_LIST, "{F1C40F}Bank: {FFFFFF}Logs", "Deposited Money\nWithdrawn Money\nTransfers\nLogins\nPassword Changes", "Show", "Back");
	return 1;
}

Player_GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

Bank_AccountCount(playerid)
{
	new query[144], Cache: find_accounts;
	mysql_format(BankSQLHandle, query, sizeof(query), "SELECT null FROM bank_accounts WHERE Owner='%e' && Disabled=0", Player_GetName(playerid));
	find_accounts = mysql_query(BankSQLHandle, query);

	new count = cache_num_rows();
	cache_delete(find_accounts);
	return count;
}

Bank_GetBalance(accountid)
{
	new query[144], Cache: get_balance;
	mysql_format(BankSQLHandle, query, sizeof(query), "SELECT Balance FROM bank_accounts WHERE ID=%d && Disabled=0", accountid);
	get_balance = mysql_query(BankSQLHandle, query);

	new balance;
	cache_get_value_name_int(0, "Balance", balance);
	cache_delete(get_balance);
	return balance;
}

Bank_GetOwner(accountid)
{
	new query[144], owner[MAX_PLAYER_NAME], Cache: get_owner;
	mysql_format(BankSQLHandle, query, sizeof(query), "SELECT Owner FROM bank_accounts WHERE ID=%d && Disabled=0", accountid);
	get_owner = mysql_query(BankSQLHandle, query);

	cache_get_value_name(0, "Owner", owner);
	cache_delete(get_owner);
	return owner;
}

Bank_ListAccounts(playerid)
{
    new query[256], Cache: get_accounts;
    mysql_format(BankSQLHandle, query, sizeof(query), "SELECT ID, Balance, LastAccess, FROM_UNIXTIME(CreatedOn, '%%d/%%m/%%Y %%H:%%i:%%s') AS Created, FROM_UNIXTIME(LastAccess, '%%d/%%m/%%Y %%H:%%i:%%s') AS Last FROM bank_accounts WHERE Owner='%e' && Disabled=0 ORDER BY CreatedOn DESC", Player_GetName(playerid));
	get_accounts = mysql_query(BankSQLHandle, query);
    new rows = cache_num_rows();

	if(rows) {
	    new string[1024], acc_id, balance, last_access, cdate[24], ldate[24];
    	format(string, sizeof(string), "ID\tBalance\tCreated On\tLast Access\n");
	    for(new i; i < rows; ++i)
	    {
	        cache_get_value_name_int(i, "ID", acc_id);
	        cache_get_value_name_int(i, "Balance", balance);
	        cache_get_value_name_int(i, "LastAccess", last_access);
        	cache_get_value_name(i, "Created", cdate);
        	cache_get_value_name(i, "Last", ldate);
        	
	        format(string, sizeof(string), "%s{FFFFFF}%d\t{2ECC71}%s\t{FFFFFF}%s\t%s\n", string, acc_id, formatInt(balance), cdate, (last_access == 0) ? ("Never") : ldate);
	    }

		ShowPlayerDialog(playerid, DIALOG_BANK_ACCOUNTS, DIALOG_STYLE_TABLIST_HEADERS, "{F1C40F}Bank: {FFFFFF}My Accounts", string, "Login", "Back");
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have any bank accounts.");
		Bank_ShowMenu(playerid);
	}

    cache_delete(get_accounts);
	return 1;
}

Bank_ShowLogs(playerid)
{
	new query[196], type = LogListType[playerid], Cache: bank_logs;
	mysql_format(BankSQLHandle, query, sizeof(query), "SELECT *, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i:%%s') as ActionDate FROM bank_logs WHERE AccountID=%d && Type=%d ORDER BY Date DESC LIMIT %d, 15", CurrentAccountID[playerid], type, LogListPage[playerid] * 15);
	bank_logs = mysql_query(BankSQLHandle, query);

	new rows = cache_num_rows();
	if(rows) {
		new list[1512], title[96], name[MAX_PLAYER_NAME], date[24];
		switch(type)
		{
		    case TYPE_LOGIN:
			{
				format(list, sizeof(list), "By\tAction Date\n");
				format(title, sizeof(title), "{F1C40F}Bank: {FFFFFF}Login History (Page %d)", LogListPage[playerid] + 1);
			}

			case TYPE_DEPOSIT:
			{
				format(list, sizeof(list), "By\tAmount\tDeposit Date\n");
				format(title, sizeof(title), "{F1C40F}Bank: {FFFFFF}Deposit History (Page %d)", LogListPage[playerid] + 1);
			}

			case TYPE_WITHDRAW:
			{
				format(list, sizeof(list), "By\tAmount\tWithdraw Date\n");
				format(title, sizeof(title), "{F1C40F}Bank: {FFFFFF}Withdraw History (Page %d)", LogListPage[playerid] + 1);
			}

			case TYPE_TRANSFER:
			{
				format(list, sizeof(list), "By\tTo Account\tAmount\tTransfer Date\n");
				format(title, sizeof(title), "{F1C40F}Bank: {FFFFFF}Transfer History (Page %d)", LogListPage[playerid] + 1);
			}

			case TYPE_PASSCHANGE:
			{
				format(list, sizeof(list), "By\tAction Date\n");
				format(title, sizeof(title), "{F1C40F}Bank: {FFFFFF}Password Changes (Page %d)", LogListPage[playerid] + 1);
			}
		}

		new amount, to_acc_id;
	    for(new i; i < rows; ++i)
	    {
	        cache_get_value_name(i, "Player", name);
        	cache_get_value_name(i, "ActionDate", date);

            switch(type)
			{
			    case TYPE_LOGIN:
				{
					format(list, sizeof(list), "%s%s\t%s\n", list, name, date);
				}

				case TYPE_DEPOSIT:
				{
				    cache_get_value_name_int(i, "Amount", amount);
					format(list, sizeof(list), "%s%s\t{2ECC71}%s\t%s\n", list, name, formatInt(amount), date);
				}

				case TYPE_WITHDRAW:
				{
				    cache_get_value_name_int(i, "Amount", amount);
					format(list, sizeof(list), "%s%s\t{2ECC71}%s\t%s\n", list, name, formatInt(amount), date);
				}

				case TYPE_TRANSFER:
				{
				    cache_get_value_name_int(i, "ToAccountID", to_acc_id);
				    cache_get_value_name_int(i, "Amount", amount);
				    
					format(list, sizeof(list), "%s%s\t%d\t{2ECC71}%s\t%s\n", list, name, to_acc_id, formatInt(amount), date);
				}

				case TYPE_PASSCHANGE:
				{
					format(list, sizeof(list), "%s%s\t%s\n", list, name, date);
				}
			}
	    }

		ShowPlayerDialog(playerid, DIALOG_BANK_LOG_PAGE, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
	}else{
		SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Can't find any more records.");
		Bank_ShowLogMenu(playerid);
	}

	cache_delete(bank_logs);
	return 1;
}

#if defined ROBBABLE_ATMS
ATM_ReturnDmgText(id)
{
 	new Float: health = ATMData[id][atmHealth], color, string[16];

	if(health < (ATM_HEALTH / 4)) {
	    color = 0xE74C3CFF;
	}else if(health < (ATM_HEALTH / 2)) {
	    color = 0xF39C12FF;
	}else{
	    color = 0x2ECC71FF;
	}

	format(string, sizeof(string), "{%06x}%.2f%%", color >>> 8, (health * 100 / ATM_HEALTH));
	return string;
}
#endif

public OnFilterScriptInit()
{
    print("  [Bank System] Initializing...");

    for(new i; i < MAX_BANKERS; i++)
    {
        BankerData[i][bankerActorID] = -1;

        #if defined BANKER_USE_MAPICON
        BankerData[i][bankerIconID] = -1;
        #endif

        BankerData[i][bankerLabel] = Text3D: -1;
    }

    for(new i; i < MAX_ATMS; i++)
    {
        ATMData[i][atmObjID] = -1;

        #if defined ATM_USE_MAPICON
        ATMData[i][atmIconID] = -1;
        #endif
        
        #if defined ROBBABLE_ATMS
        ATMData[i][atmTimer] = ATMData[i][atmPickup] = -1;
        ATMData[i][atmHealth] = ATM_HEALTH;
        #endif

        ATMData[i][atmLabel] = Text3D: -1;
    }

	BankSQLHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DBNAME);
	mysql_log(ERROR | WARNING);
	if(mysql_errno()) return printf("  [Bank System] Can't connect to MySQL. (Error #%d)", mysql_errno());

	// create tables if they don't exist
	mysql_tquery(BankSQLHandle, "CREATE TABLE IF NOT EXISTS `bankers` (\
	  `ID` int(11) NOT NULL,\
	  `Skin` smallint(3) NOT NULL,\
	  `PosX` float NOT NULL,\
	  `PosY` float NOT NULL,\
	  `PosZ` float NOT NULL,\
	  `PosA` float NOT NULL\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

    mysql_tquery(BankSQLHandle, "CREATE TABLE IF NOT EXISTS `bank_atms` (\
	  `ID` int(11) NOT NULL,\
	  `PosX` float NOT NULL,\
	  `PosY` float NOT NULL,\
	  `PosZ` float NOT NULL,\
	  `RotX` float NOT NULL,\
	  `RotY` float NOT NULL,\
	  `RotZ` float NOT NULL\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

	mysql_tquery(BankSQLHandle, "CREATE TABLE IF NOT EXISTS `bank_accounts` (\
	  `ID` int(11) NOT NULL auto_increment,\
	  `Owner` varchar(24) NOT NULL,\
	  `Password` varchar(32) NOT NULL,\
	  `Balance` int(11) NOT NULL,\
	  `CreatedOn` int(11) NOT NULL,\
	  `LastAccess` int(11) NOT NULL,\
	  `Disabled` smallint(1) NOT NULL,\
	  PRIMARY KEY  (`ID`)\
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

	new query[512];
	mysql_format(BankSQLHandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `bank_logs` (\
	  	`ID` int(11) NOT NULL auto_increment,\
	  	`AccountID` int(11) NOT NULL,\
	  	`ToAccountID` int(11) NOT NULL default '-1',\
	  	`Type` smallint(1) NOT NULL,\
	  	`Player` varchar(24) NOT NULL,\
	  	`Amount` int(11) NOT NULL,\
	  	`Date` int(11) NOT NULL,");

	mysql_format(BankSQLHandle, query, sizeof(query), "%s\
 		PRIMARY KEY  (`ID`),\
 		KEY `bank_logs_ibfk_1` (`AccountID`),\
 		CONSTRAINT `bank_logs_ibfk_1` FOREIGN KEY (`AccountID`) REFERENCES `bank_accounts` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE\
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;", query);

	mysql_tquery(BankSQLHandle, query);

    print("  [Bank System] Connected to MySQL, loading data...");
	mysql_tquery(BankSQLHandle, "SELECT * FROM bankers", "LoadBankers");
	mysql_tquery(BankSQLHandle, "SELECT * FROM bank_atms", "LoadATMs");
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Bankers)
	{
	    if(IsValidActor(BankerData[i][bankerActorID])) DestroyActor(BankerData[i][bankerActorID]);
	}

    print("  [Bank System] Unloaded.");
	mysql_close(BankSQLHandle);
	return 1;
}

public OnPlayerConnect(playerid)
{
	CurrentAccountID[playerid] = -1;
	LogListType[playerid] = TYPE_NONE;
	LogListPage[playerid] = 0;

	EditingATMID[playerid] = -1;
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_MENU_NOLOGIN:
	    {
	        if(!response) return 1;
	        if(listitem == 0)
	        {
	            if(GetPVarInt(playerid, "usingATM"))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't do this at an ATM, visit a banker.");
					return Bank_ShowMenu(playerid);
				}

	            if(ACCOUNT_PRICE > GetPlayerMoney(playerid))
	            {
	                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough money to create a bank account.");
	                return Bank_ShowMenu(playerid);
	            }

				#if defined ACCOUNT_CLIMIT
				if(Bank_AccountCount(playerid) >= ACCOUNT_CLIMIT)
	            {
	                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't create any more bank accounts.");
	                return Bank_ShowMenu(playerid);
	            }
				#endif

				ShowPlayerDialog(playerid, DIALOG_BANK_CREATE_ACCOUNT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Create Account", "Choose a password for your new bank account:", "Create", "Back");
	        }

	        if(listitem == 1) Bank_ListAccounts(playerid);
	        if(listitem == 2) ShowPlayerDialog(playerid, DIALOG_BANK_LOGIN_ID, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Login", "Account ID:", "Continue", "Cancel");
	        return 1;
	    }
     	/* ---------------------------------------------------------------------- */
     	case DIALOG_BANK_MENU:
		{
		    if(!response) return 1;
		    if(listitem == 0)
	        {
	            if(GetPVarInt(playerid, "usingATM"))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't do this at an ATM, visit a banker.");
					return Bank_ShowMenu(playerid);
				}

	            if(ACCOUNT_PRICE > GetPlayerMoney(playerid))
	            {
	                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough money to create a bank account.");
	                return Bank_ShowMenu(playerid);
	            }

				#if defined ACCOUNT_CLIMIT
				if(Bank_AccountCount(playerid) >= ACCOUNT_CLIMIT)
	            {
	                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't create any more bank accounts.");
	                return Bank_ShowMenu(playerid);
	            }
				#endif

				ShowPlayerDialog(playerid, DIALOG_BANK_CREATE_ACCOUNT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Create Account", "Choose a password for your new bank account:", "Create", "Back");
	        }

	        if(listitem == 1) Bank_ListAccounts(playerid);
	        if(listitem == 2) ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Deposit", "How much money do you want to deposit?", "Deposit", "Back");
            if(listitem == 3) ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Withdraw", "How much money do you want to withdraw?", "Withdraw", "Back");
			if(listitem == 4) ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_1, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "Specify an account ID:", "Continue", "Back");
            if(listitem == 5)
			{
			    if(GetPVarInt(playerid, "usingATM"))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't do this at an ATM, visit a banker.");
					return Bank_ShowMenu(playerid);
				}

				Bank_ShowLogMenu(playerid);
			}

			if(listitem == 6)
			{
			    if(GetPVarInt(playerid, "usingATM"))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't do this at an ATM, visit a banker.");
					return Bank_ShowMenu(playerid);
				}

				if(strcmp(Bank_GetOwner(CurrentAccountID[playerid]), Player_GetName(playerid)))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only the account owner can do this.");
				    return Bank_ShowMenu(playerid);
				}

				ShowPlayerDialog(playerid, DIALOG_BANK_PASSWORD, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Change Password", "Write a new password:", "Change", "Back");
			}

			if(listitem == 7)
			{
			    if(GetPVarInt(playerid, "usingATM"))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't do this at an ATM, visit a banker.");
					return Bank_ShowMenu(playerid);
				}

			    if(strcmp(Bank_GetOwner(CurrentAccountID[playerid]), Player_GetName(playerid)))
				{
				    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only the account owner can do this.");
				    return Bank_ShowMenu(playerid);
				}

				ShowPlayerDialog(playerid, DIALOG_BANK_REMOVE, DIALOG_STYLE_MSGBOX, "{F1C40F}Bank: {FFFFFF}Remove Account", "Are you sure? This account will get deleted {E74C3C}permanently.", "Yes", "Back");
				// https://youtu.be/rcjpags7JT8 - because it doesn't get deleted actually
			}

			if(listitem == 8)
			{
			    SendClientMessage(playerid, 0x3498DBFF, "BANK: {FFFFFF}Successfully logged out.");

			    CurrentAccountID[playerid] = -1;
			    Bank_ShowMenu(playerid);
			}
		}
        /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_CREATE_ACCOUNT:
	    {
	        if(!response) return Bank_ShowMenu(playerid);
	        if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_CREATE_ACCOUNT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Create Account", "{E74C3C}You can't leave your account password empty.\n\n{FFFFFF}Choose a password for your new bank account:", "Create", "Back");
			if(strlen(inputtext) > 16) return ShowPlayerDialog(playerid, DIALOG_BANK_CREATE_ACCOUNT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Create Account", "{E74C3C}Account password can't be more than 16 characters.\n\n{FFFFFF}Choose a password for your new bank account:", "Create", "Back");
			if(ACCOUNT_PRICE > GetPlayerMoney(playerid))
            {
                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You don't have enough money to create a bank account.");
                return Bank_ShowMenu(playerid);
            }

			#if defined ACCOUNT_CLIMIT
			if(Bank_AccountCount(playerid) >= ACCOUNT_CLIMIT)
            {
                SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't create any more bank accounts.");
                return Bank_ShowMenu(playerid);
            }
			#endif

			new query[144];
			mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bank_accounts SET Owner='%e', Password=md5('%e'), CreatedOn=UNIX_TIMESTAMP()", Player_GetName(playerid), inputtext);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountCreated", "is", playerid, inputtext);
	        return 1;
	    }
	    /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_ACCOUNTS:
	    {
            if(!response) return Bank_ShowMenu(playerid);

            SetPVarInt(playerid, "bankLoginAccount", strval(inputtext));
			ShowPlayerDialog(playerid, DIALOG_BANK_LOGIN_PASS, DIALOG_STYLE_PASSWORD, "{F1C40F}Bank: {FFFFFF}Login", "Account Password:", "Login", "Cancel");
	        return 1;
	    }
	    /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_LOGIN_ID:
	    {
	        if(!response) return Bank_ShowMenu(playerid);
	        if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_LOGIN_ID, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Login", "{E74C3C}You can't leave the ID empty.\n\n{FFFFFF}Account ID:", "Continue", "Cancel");

			SetPVarInt(playerid, "bankLoginAccount", strval(inputtext));
			ShowPlayerDialog(playerid, DIALOG_BANK_LOGIN_PASS, DIALOG_STYLE_PASSWORD, "{F1C40F}Bank: {FFFFFF}Login", "Account Password:", "Login", "Cancel");
			return 1;
	    }
	    /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_LOGIN_PASS:
	    {
	        if(!response) return Bank_ShowMenu(playerid);
	        if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_LOGIN_PASS, DIALOG_STYLE_PASSWORD, "{F1C40F}Bank: {FFFFFF}Login", "{E74C3C}You can't leave the password empty.\n\n{FFFFFF}Account Password:", "Login", "Cancel");

			new query[200], id = GetPVarInt(playerid, "bankLoginAccount");
			mysql_format(BankSQLHandle, query, sizeof(query), "SELECT Owner, LastAccess, FROM_UNIXTIME(LastAccess, '%%d/%%m/%%Y %%H:%%i:%%s') AS Last FROM bank_accounts WHERE ID=%d && Password=md5('%e') && Disabled=0 LIMIT 1", id, inputtext);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountLogin", "ii", playerid, id);
			return 1;
	    }
	    /* ---------------------------------------------------------------------- */
	    case DIALOG_BANK_DEPOSIT:
	    {
			if(!response) return Bank_ShowMenu(playerid);
			if(CurrentAccountID[playerid] == -1) return 1;
     		if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Deposit", "{E74C3C}You can't leave the input empty.\n\n{FFFFFF}How much money do you want to deposit?", "Deposit", "Back");
			new amount = strval(inputtext);
			if(!(1 <= amount <= (GetPVarInt(playerid, "usingATM") ? 5000000 : 250000000))) return ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Deposit", "{E74C3C}You can't deposit less than $1 or more than $250,000,000 at once. ($5,000,000 at once on ATMs)\n\n{FFFFFF}How much money do you want to deposit?", "Deposit", "Back");
			if(amount > GetPlayerMoney(playerid)) return ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Deposit", "{E74C3C}You don't have enough money.\n\n{FFFFFF}How much money do you want to deposit?", "Deposit", "Back");
			if((amount + Bank_GetBalance(CurrentAccountID[playerid])) > ACCOUNT_LIMIT)
			{
   				SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You can't deposit any more money to this account.");
			    return Bank_ShowMenu(playerid);
			}

			new query[96];
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Balance=Balance+%d WHERE ID=%d && Disabled=0", amount, CurrentAccountID[playerid]);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountDeposit", "ii", playerid, amount);
			return 1;
		}
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_WITHDRAW:
	    {
			if(!response) return Bank_ShowMenu(playerid);
			if(CurrentAccountID[playerid] == -1) return 1;
     		if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Withdraw", "{E74C3C}You can't leave the input empty.\n\n{FFFFFF}How much money do you want to withdraw?", "Withdraw", "Back");
			new amount = strval(inputtext);
			if(!(1 <= amount <= (GetPVarInt(playerid, "usingATM") ? 5000000 : 250000000))) return ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Withdraw", "{E74C3C}You can't withdraw less than $1 or more than $250,000,000 at once. ($5,000,000 at once on ATMs)\n\n{FFFFFF}How much money do you want to withdraw?", "Withdraw", "Back");
			if(amount > Bank_GetBalance(CurrentAccountID[playerid])) return ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Withdraw", "{E74C3C}Account doesn't have enough money.\n\n{FFFFFF}How much money do you want to withdraw?", "Withdraw", "Back");

			new query[96];
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Balance=Balance-%d WHERE ID=%d && Disabled=0", amount, CurrentAccountID[playerid]);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountWithdraw", "ii", playerid, amount);
			return 1;
		}
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_TRANSFER_1:
	    {
			if(!response) return Bank_ShowMenu(playerid);
			if(CurrentAccountID[playerid] == -1) return 1;
     		if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_1, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "{E74C3C}You can't leave the input empty.\n\n{FFFFFF}Specify an account ID:", "Continue", "Back");
            if(strval(inputtext) == CurrentAccountID[playerid]) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_1, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "{E74C3C}You can't transfer money to your current account.\n\n{FFFFFF}Specify an account ID:", "Continue", "Back");
            SetPVarInt(playerid, "bankTransferAccount", strval(inputtext));
            ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_2, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "Specify an amount:", "Transfer", "Back");
            return 1;
		}
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_TRANSFER_2:
        {
            if(!response) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_1, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "Specify an account ID:", "Continue", "Back");
            if(CurrentAccountID[playerid] == -1) return 1;
			if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_2, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "{E74C3C}You can't leave the input empty.\n\n{FFFFFF}Specify an amount:", "Transfer", "Back");
            new amount = strval(inputtext);
			if(!(1 <= amount <= (GetPVarInt(playerid, "usingATM") ? 5000000 : 250000000))) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_2, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "{E74C3C}You can't transfer less than $1 or more than $250,000,000 at once. ($5,000,000 on ATMs)\n\n{FFFFFF}Specify an amount:", "Transfer", "Back");
            if(amount > Bank_GetBalance(CurrentAccountID[playerid])) return ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_2, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Transfer", "{E74C3C}Account doesn't have enough money.\n\n{FFFFFF}Specify an amount:", "Transfer", "Back");
			new id = GetPVarInt(playerid, "bankTransferAccount");
			if((amount + Bank_GetBalance(id)) > ACCOUNT_LIMIT)
			{
				SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Can't deposit any more money to the account you specified.");
				return Bank_ShowMenu(playerid);
			}

			new query[96];
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Balance=Balance+%d WHERE ID=%d && Disabled=0", amount, id);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountTransfer", "iii", playerid, id, amount);
            return 1;
        }
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_PASSWORD:
        {
        	if(!response) return Bank_ShowMenu(playerid);
        	if(CurrentAccountID[playerid] == -1) return 1;
	        if(isnull(inputtext)) return ShowPlayerDialog(playerid, DIALOG_BANK_PASSWORD, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Change Password", "{E74C3C}You can't leave the input empty.\n\n{FFFFFF}Write a new password:", "Change", "Back");
			if(strlen(inputtext) > 16) return ShowPlayerDialog(playerid, DIALOG_BANK_PASSWORD, DIALOG_STYLE_INPUT, "{F1C40F}Bank: {FFFFFF}Change Password", "{E74C3C}New password can't be more than 16 characters.\n\n{FFFFFF}Write a new password:", "Change", "Back");

			new query[128];
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Password=md5('%e') WHERE ID=%d && Disabled=0", inputtext, CurrentAccountID[playerid]);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountPassChange", "is", playerid, inputtext);
	        return 1;
	    }
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_REMOVE:
        {
            if(!response) return Bank_ShowMenu(playerid);
            if(CurrentAccountID[playerid] == -1) return 1;

            new query[96], amount = Bank_GetBalance(CurrentAccountID[playerid]);
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Disabled=1 WHERE ID=%d", CurrentAccountID[playerid]);
			mysql_tquery(BankSQLHandle, query, "OnBankAccountDeleted", "iii", playerid, CurrentAccountID[playerid], amount);
            return 1;
        }
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_LOGS:
        {
            if(!response) return Bank_ShowMenu(playerid);
            if(CurrentAccountID[playerid] == -1) return 1;

            new typelist[6] = {TYPE_NONE, TYPE_DEPOSIT, TYPE_WITHDRAW, TYPE_TRANSFER, TYPE_LOGIN, TYPE_PASSCHANGE};
            LogListType[playerid] = typelist[listitem + 1];
            LogListPage[playerid] = 0;
            Bank_ShowLogs(playerid);
            return 1;
   		}
        /* ---------------------------------------------------------------------- */
        case DIALOG_BANK_LOG_PAGE:
		{
		    if(CurrentAccountID[playerid] == -1 || LogListType[playerid] == TYPE_NONE) return 1;
			if(!response) {
			    LogListPage[playerid]--;
			    if(LogListPage[playerid] < 0) return Bank_ShowLogMenu(playerid);
			}else{
			    LogListPage[playerid]++;
			}

			Bank_ShowLogs(playerid);
		    return 1;
		}
        /* ---------------------------------------------------------------------- */
	}

	return 0;
}

public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if(Iter_Contains(ATMs, EditingATMID[playerid]))
	{
	    if(response == EDIT_RESPONSE_FINAL)
	    {
	        new id = EditingATMID[playerid];
	        ATMData[id][atmX] = x;
	        ATMData[id][atmY] = y;
	        ATMData[id][atmZ] = z;
	        ATMData[id][atmRX] = rx;
	        ATMData[id][atmRY] = ry;
	        ATMData[id][atmRZ] = rz;

	        SetDynamicObjectPos(objectid, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ]);
	        SetDynamicObjectRot(objectid, ATMData[id][atmRX], ATMData[id][atmRY], ATMData[id][atmRZ]);

	        #if defined ATM_USE_MAPICON
			Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, ATMData[id][atmIconID], E_STREAMER_X, ATMData[id][atmX]);
			Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, ATMData[id][atmIconID], E_STREAMER_Y, ATMData[id][atmY]);
			Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, ATMData[id][atmIconID], E_STREAMER_Z, ATMData[id][atmZ]);
			#endif

			Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, ATMData[id][atmLabel], E_STREAMER_X, ATMData[id][atmX]);
			Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, ATMData[id][atmLabel], E_STREAMER_Y, ATMData[id][atmY]);
			Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, ATMData[id][atmLabel], E_STREAMER_Z, ATMData[id][atmZ] + 0.85);

			new query[144];
			mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_atms SET PosX='%f', PosY='%f', PosZ='%f', RotX='%f', RotY='%f', RotZ='%f' WHERE ID=%d", x, y, z, rx, ry, rz, id);
			mysql_tquery(BankSQLHandle, query);

	        EditingATMID[playerid] = -1;
	    }

	    if(response == EDIT_RESPONSE_CANCEL)
	    {
	        new id = EditingATMID[playerid];
	        SetDynamicObjectPos(objectid, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ]);
	        SetDynamicObjectRot(objectid, ATMData[id][atmRX], ATMData[id][atmRY], ATMData[id][atmRZ]);
	        EditingATMID[playerid] = -1;
	    }
	}

	return 1;
}

#if defined ROBBABLE_ATMS
public OnPlayerShootDynamicObject(playerid, weaponid, STREAMER_TAG_OBJECT objectid, Float:x, Float:y, Float:z)
{
    if(Streamer_GetIntData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID) == 19324)
	{
		new dataArray[E_ATMDATA];
		Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, dataArray);

		if(strlen(dataArray[IDString]) && !strcmp(dataArray[IDString], "atm_sys") && Iter_Contains(ATMs, dataArray[refID]) && ATMData[ dataArray[refID] ][atmRegen] == 0)
	    {
			new id = dataArray[refID], string[64], Float: damage = GetWeaponDamageFromDistance(weaponid, GetPlayerDistanceFromPoint(playerid, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ])) / 1.5;
			ATMData[id][atmHealth] -= damage;

			if(ATMData[id][atmHealth] < 0.0) {
			    ATMData[id][atmHealth] = 0.0;

			    format(string, sizeof(string), "ATM (%d)\n\n{FFFFFF}Out of Service\n{E74C3C}%s", id, ConvertToMinutes(ATM_REGEN));
			    UpdateDynamic3DTextLabelText(ATMData[id][atmLabel], 0x1ABC9CFF, string);

			    ATMData[id][atmRegen] = ATM_REGEN;
			    ATMData[id][atmTimer] = SetTimerEx("ATM_Regen", 1000, true, "i", id);
			    Streamer_SetIntData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID, 2943);

			    new Float: a = ATMData[id][atmRZ] + 180.0;
			    ATMData[id][atmPickup] = CreateDynamicPickup(1212, 1, ATMData[id][atmX] + (1.25 * floatsin(-a, degrees)), ATMData[id][atmY] + (1.25 * floatcos(-a, degrees)), ATMData[id][atmZ] - 0.25);

				if(IsValidDynamicPickup(ATMData[id][atmPickup]))
				{
				    new pickupDataArray[E_ATMDATA];
					format(pickupDataArray[IDString], 8, "atm_sys");
		        	pickupDataArray[refID] = id;
		        	Streamer_SetArrayData(STREAMER_TYPE_PICKUP, ATMData[id][atmPickup], E_STREAMER_EXTRA_ID, pickupDataArray);
				}

				Streamer_Update(playerid);
			}else{
			    format(string, sizeof(string), "ATM (%d)\n\n{FFFFFF}Use {F1C40F}/atm!\n%s", id, ATM_ReturnDmgText(id));
			    UpdateDynamic3DTextLabelText(ATMData[id][atmLabel], 0x1ABC9CFF, string);
			}

			PlayerPlaySound(playerid, 17802, 0.0, 0.0, 0.0);
		}
	}

	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    if(Streamer_GetIntData(STREAMER_TYPE_PICKUP, pickupid, E_STREAMER_MODEL_ID) == 1212)
	{
 		new dataArray[E_ATMDATA];
		Streamer_GetArrayData(STREAMER_TYPE_PICKUP, pickupid, E_STREAMER_EXTRA_ID, dataArray);

		if(strlen(dataArray[IDString]) && !strcmp(dataArray[IDString], "atm_sys"))
	    {
            new money = RandomEx(ATM_ROB_MIN, ATM_ROB_MAX), string[64];
		    format(string, sizeof(string), "ATM: {FFFFFF}You stole {2ECC71}%s {FFFFFF}from the ATM.", formatInt(money));
	   		SendClientMessage(playerid, 0x3498DBFF, string);
	   		GivePlayerMoney(playerid, money);

	   		ATMData[ dataArray[refID] ][atmPickup] = -1;
	   		DestroyDynamicPickup(pickupid);
		}
	}

	return 1;
}
#endif

forward LoadBankers();
public LoadBankers()
{
	new rows = cache_num_rows();
	if(rows)
	{
	    new id, label_string[64];
	    for(new i; i < rows; i++)
		{
		    cache_get_value_name_int(i, "ID", id);
		    cache_get_value_name_int(i, "Skin", BankerData[id][Skin]);
		    cache_get_value_name_float(i, "PosX", BankerData[id][bankerX]);
		    cache_get_value_name_float(i, "PosY", BankerData[id][bankerY]);
		    cache_get_value_name_float(i, "PosZ", BankerData[id][bankerZ]);
		    cache_get_value_name_float(i, "PosA", BankerData[id][bankerA]);

		    BankerData[id][bankerActorID] = CreateActor(BankerData[id][Skin], BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA]);
		    if(!IsValidActor(BankerData[id][bankerActorID])) {
				printf("  [Bank System] Couldn't create an actor for banker ID %d.", id);
			}else{
			    SetActorInvulnerable(BankerData[id][bankerActorID], true); // people may use a version where actors aren't invulnerable by default
			}

			#if defined BANKER_USE_MAPICON
			BankerData[id][bankerIconID] = CreateDynamicMapIcon(BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], 58, 0, .streamdistance = BANKER_ICON_RANGE);
			#endif

			format(label_string, sizeof(label_string), "Banker (%d)\n\n{FFFFFF}Use {F1C40F}/bank!", id);
			BankerData[id][bankerLabel] = CreateDynamic3DTextLabel(label_string, 0x1ABC9CFF, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ] + 0.25, 5.0, .testlos = 1);

			Iter_Add(Bankers, id);
		}
	}

	printf("  [Bank System] Loaded %d bankers.", Iter_Count(Bankers));
	return 1;
}

forward LoadATMs();
public LoadATMs()
{
	new rows = cache_num_rows();
	if(rows)
	{
	    new id, label_string[64];
	    #if defined ROBBABLE_ATMS
		new dataArray[E_ATMDATA];
	    #endif
	    
	    for(new i; i < rows; i++)
		{
		    cache_get_value_name_int(i, "ID", id);
	     	cache_get_value_name_float(i, "PosX", ATMData[id][atmX]);
	     	cache_get_value_name_float(i, "PosY", ATMData[id][atmY]);
	     	cache_get_value_name_float(i, "PosZ", ATMData[id][atmZ]);
	     	cache_get_value_name_float(i, "RotX", ATMData[id][atmRX]);
	     	cache_get_value_name_float(i, "RotY", ATMData[id][atmRY]);
	     	cache_get_value_name_float(i, "RotZ", ATMData[id][atmRZ]);

		    ATMData[id][atmObjID] = CreateDynamicObject(19324, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ], ATMData[id][atmRX], ATMData[id][atmRY], ATMData[id][atmRZ]);

			#if defined ROBBABLE_ATMS
		    if(IsValidDynamicObject(ATMData[id][atmObjID])) {
		        format(dataArray[IDString], 8, "atm_sys");
		        dataArray[refID] = id;

		        Streamer_SetArrayData(STREAMER_TYPE_OBJECT, ATMData[id][atmObjID], E_STREAMER_EXTRA_ID, dataArray);
		    }else{
				printf("  [Bank System] Couldn't create an ATM object for ATM ID %d.", id);
		    }
			#else
			if(!IsValidDynamicObject(ATMData[id][atmObjID])) printf("  [Bank System] Couldn't create an ATM object for ATM ID %d.", id);
			#endif
			
			#if defined ATM_USE_MAPICON
			ATMData[id][atmIconID] = CreateDynamicMapIcon(ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ], 52, 0, .streamdistance = ATM_ICON_RANGE);
			#endif

			format(label_string, sizeof(label_string), "ATM (%d)\n\n{FFFFFF}Use {F1C40F}/atm!", id);
			ATMData[id][atmLabel] = CreateDynamic3DTextLabel(label_string, 0x1ABC9CFF, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ] + 0.85, 5.0, .testlos = 1);

			Iter_Add(ATMs, id);
		}
	}

    printf("  [Bank System] Loaded %d ATMs.", Iter_Count(ATMs));
	return 1;
}

forward OnBankAccountCreated(playerid, pass[]);
public OnBankAccountCreated(playerid, pass[])
{
	GivePlayerMoney(playerid, -ACCOUNT_PRICE);

	new id = cache_insert_id(), string[64];
	SendClientMessage(playerid, 0x3498DBFF, "BANK: {FFFFFF}Successfully created an account for you!");

	format(string, sizeof(string), "BANK: {FFFFFF}Your account ID: {F1C40F}%d", id);
	SendClientMessage(playerid, 0x3498DBFF, string);

	format(string, sizeof(string), "BANK: {FFFFFF}Your account password: {F1C40F}%s", pass);
	SendClientMessage(playerid, 0x3498DBFF, string);
	return 1;
}

forward OnBankAccountLogin(playerid, id);
public OnBankAccountLogin(playerid, id)
{
	if(cache_num_rows() > 0) {
	    new string[128], owner[MAX_PLAYER_NAME], last_access, ldate[24];
	    cache_get_value_name(0, "Owner", owner);
	    cache_get_value_name_int(0, "LastAccess", last_access);
	    cache_get_value_name(0, "Last", ldate);

	    format(string, sizeof(string), "BANK: {FFFFFF}This account is owned by {F1C40F}%s.", owner);
	    SendClientMessage(playerid, 0x3498DBFF, string);
	    format(string, sizeof(string), "BANK: {FFFFFF}Last Accessed On: {F1C40F}%s", (last_access == 0) ? ("Never") : ldate);
	    SendClientMessage(playerid, 0x3498DBFF, string);

	    CurrentAccountID[playerid] = id;
	    Bank_ShowMenu(playerid);

	    new query[96];
	    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET LastAccess=UNIX_TIMESTAMP() WHERE ID=%d && Disabled=0", id);
	    mysql_tquery(BankSQLHandle, query);

	    Bank_SaveLog(playerid, TYPE_LOGIN, id, -1, 0);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid credentials.");
	    Bank_ShowMenu(playerid);
	}

	return 1;
}

forward OnBankAccountDeposit(playerid, amount);
public OnBankAccountDeposit(playerid, amount)
{
	if(cache_affected_rows() > 0) {
	    new string[64];
	    format(string, sizeof(string), "BANK: {FFFFFF}Successfully deposited {2ECC71}%s.", formatInt(amount));
		SendClientMessage(playerid, 0x3498DBFF, string);

	    GivePlayerMoney(playerid, -amount);
	    Bank_SaveLog(playerid, TYPE_DEPOSIT, CurrentAccountID[playerid], -1, amount);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Transaction failed.");
	}

	Bank_ShowMenu(playerid);
	return 1;
}

forward OnBankAccountWithdraw(playerid, amount);
public OnBankAccountWithdraw(playerid, amount)
{
	if(cache_affected_rows() > 0) {
	    new string[64];
	    format(string, sizeof(string), "BANK: {FFFFFF}Successfully withdrawn {2ECC71}%s.", formatInt(amount));
		SendClientMessage(playerid, 0x3498DBFF, string);

	    GivePlayerMoney(playerid, amount);
	    Bank_SaveLog(playerid, TYPE_WITHDRAW, CurrentAccountID[playerid], -1, amount);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Transaction failed.");
	}

    Bank_ShowMenu(playerid);
	return 1;
}

forward OnBankAccountTransfer(playerid, id, amount);
public OnBankAccountTransfer(playerid, id, amount)
{
	if(cache_affected_rows() > 0) {
		new query[144];
		mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Balance=Balance-%d WHERE ID=%d && Disabled=0", amount, CurrentAccountID[playerid]);
		mysql_tquery(BankSQLHandle, query, "OnBankAccountTransferDone", "iii", playerid, id, amount);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Transaction failed.");
	    Bank_ShowMenu(playerid);
	}

	return 1;
}

forward OnBankAccountTransferDone(playerid, id, amount);
public OnBankAccountTransferDone(playerid, id, amount)
{
	if(cache_affected_rows() > 0) {
	    new string[128];
	    format(string, sizeof(string), "BANK: {FFFFFF}Successfully transferred {2ECC71}%s {FFFFFF}to account ID {F1C40F}%d.", formatInt(amount), id);
		SendClientMessage(playerid, 0x3498DBFF, string);

		Bank_SaveLog(playerid, TYPE_TRANSFER, CurrentAccountID[playerid], id, amount);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Transaction failed.");

	}

    Bank_ShowMenu(playerid);
	return 1;
}

forward OnBankAccountPassChange(playerid, newpass[]);
public OnBankAccountPassChange(playerid, newpass[])
{
	if(cache_affected_rows() > 0) {
	    new string[128];
	    format(string, sizeof(string), "BANK: {FFFFFF}Account password set to {F1C40F}%s.", newpass);
		SendClientMessage(playerid, 0x3498DBFF, string);

        Bank_SaveLog(playerid, TYPE_PASSCHANGE, CurrentAccountID[playerid], -1, 0);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Password change failed.");
	}

    Bank_ShowMenu(playerid);
	return 1;
}

forward OnBankAccountDeleted(playerid, id, amount);
public OnBankAccountDeleted(playerid, id, amount)
{
    if(cache_affected_rows() > 0) {
        GivePlayerMoney(playerid, amount);

        foreach(new i : Player)
        {
            if(i == playerid) continue;
            if(CurrentAccountID[i] == id) CurrentAccountID[i] = -1;
        }

	    new string[128];
	    format(string, sizeof(string), "BANK: {FFFFFF}Account removed, you got the {2ECC71}%s {FFFFFF}left in the account.", formatInt(amount));
		SendClientMessage(playerid, 0x3498DBFF, string);
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Account removal failed.");
	}

	CurrentAccountID[playerid] = -1;
    Bank_ShowMenu(playerid);
	return 1;
}

forward OnBankAccountAdminEdit(playerid);
public OnBankAccountAdminEdit(playerid)
{
    if(cache_affected_rows() > 0) {
        SendClientMessage(playerid, 0x3498DBFF, "BANK: {FFFFFF}Account edited.");
	}else{
	    SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Account editing failed. (No affected rows)");
	}

	return 1;
}

#if defined ROBBABLE_ATMS
forward ATM_Regen(id);
public ATM_Regen(id)
{
    new string[64];

	if(ATMData[id][atmRegen] > 1) {
	    ATMData[id][atmRegen]--;

        format(string, sizeof(string), "ATM (%d)\n\n{FFFFFF}Out of Service\n{E74C3C}%s", id, ConvertToMinutes(ATMData[id][atmRegen]));
	    UpdateDynamic3DTextLabelText(ATMData[id][atmLabel], 0x1ABC9CFF, string);
	}else if(ATMData[id][atmRegen] == 1) {
	    if(IsValidDynamicPickup(ATMData[id][atmPickup])) DestroyDynamicPickup(ATMData[id][atmPickup]);
	    KillTimer(ATMData[id][atmTimer]);

	    ATMData[id][atmHealth] = ATM_HEALTH;
	    ATMData[id][atmRegen] = 0;
	    ATMData[id][atmTimer] = ATMData[id][atmPickup] = -1;

	    Streamer_SetIntData(STREAMER_TYPE_OBJECT, ATMData[id][atmObjID], E_STREAMER_MODEL_ID, 19324);

	    format(string, sizeof(string), "ATM (%d)\n\n{FFFFFF}Use {F1C40F}/atm!", id);
		UpdateDynamic3DTextLabelText(ATMData[id][atmLabel], 0x1ABC9CFF, string);
	}

	return 1;
}
#endif

// Player Commands
CMD:bank(playerid, params[])
{
	if(!IsPlayerNearBanker(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near a banker.");
	SetPVarInt(playerid, "usingATM", 0);
	Bank_ShowMenu(playerid);
	return 1;
}

CMD:atm(playerid, params[])
{
	new id = GetClosestATM(playerid);
    if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near an ATM.");
    #if defined ROBBABLE_ATMS
    if(ATMData[id][atmRegen] > 0) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}This ATM is out of service.");
    #endif

    SetPVarInt(playerid, "usingATM", 1);
	Bank_ShowMenu(playerid);
	return 1;
}

// Admin Commands
CMD:asetowner(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, owner[MAX_PLAYER_NAME];
    if(sscanf(params, "is[24]", id, owner)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/asetowner [account id] [new owner]");
    new query[128];
    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Owner='%e' WHERE ID=%d", owner, id);
    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

CMD:asetpassword(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, password[16];
    if(sscanf(params, "is[16]", id, password)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/asetpassword [account id] [new password]");
    new query[128];
    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Password=md5('%e') WHERE ID=%d", password, id);
    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

CMD:asetbalance(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, balance;
    if(sscanf(params, "ii", id, balance)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/asetbalance [account id] [balance]");
    if(balance > ACCOUNT_LIMIT) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Balance you specified exceeds account money limit.");
    new query[128];
    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Balance=%d WHERE ID=%d", balance, id);
    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

CMD:aclearlogs(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id, type;
    if(sscanf(params, "iI(0)", id, type))
	{
	    SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/aclearlogs [account id] [log type (optional)]");
	    SendClientMessage(playerid, 0xE88732FF, "TYPES: {FFFFFF}0- All | 1- Logins | 2- Deposits | 3- Withdraws | 4- Transfers | 5- Password Changes");
		return 1;
	}

	new query[128];
	if(type > 0) {
	    mysql_format(BankSQLHandle, query, sizeof(query), "DELETE FROM bank_logs WHERE AccountID=%d && Type=%d", id, type);
	}else{
	    mysql_format(BankSQLHandle, query, sizeof(query), "DELETE FROM bank_logs WHERE AccountID=%d", id);
	}

    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

CMD:aremoveaccount(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id;
    if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/aremoveaccount [account id]");
    foreach(new i : Player)
    {
        if(CurrentAccountID[i] == id) CurrentAccountID[i] = -1;
    }

    new query[128];
    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Disabled=1 WHERE ID=%d", id);
    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

CMD:areturnaccount(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
    new id;
    if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/areturnaccount [account id]");
    new query[128];
    mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bank_accounts SET Disabled=0 WHERE ID=%d", id);
    mysql_tquery(BankSQLHandle, query, "OnBankAccountAdminEdit", "i", playerid);
	return 1;
}

// Admin Commands for Bankers
CMD:createbanker(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id = Iter_Free(Bankers);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Can't create any more bankers.");
	new skin;
	if(sscanf(params, "i", skin)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/createbanker [skin id]");
	if(!(0 <= skin <= 311)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid skin ID.");
	BankerData[id][Skin] = skin;
	GetPlayerPos(playerid, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ]);
	GetPlayerFacingAngle(playerid, BankerData[id][bankerA]);
	SetPlayerPos(playerid, BankerData[id][bankerX] + (1.0 * floatsin(-BankerData[id][bankerA], degrees)), BankerData[id][bankerY] + (1.0 * floatcos(-BankerData[id][bankerA], degrees)), BankerData[id][bankerZ]);

	BankerData[id][bankerActorID] = CreateActor(skin, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA]);
	if(IsValidActor(BankerData[id][bankerActorID])) SetActorInvulnerable(BankerData[id][bankerActorID], true);

	#if defined BANKER_USE_MAPICON
	BankerData[id][bankerIconID] = CreateDynamicMapIcon(BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], 58, 0, .streamdistance = BANKER_ICON_RANGE);
	#endif

	new label_string[64];
	format(label_string, sizeof(label_string), "Banker (%d)\n\n{FFFFFF}Use {F1C40F}/bank!", id);
	BankerData[id][bankerLabel] = CreateDynamic3DTextLabel(label_string, 0x1ABC9CFF, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ] + 0.25, 5.0, .testlos = 1);

	new query[144];
	mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bankers SET ID=%d, Skin=%d, PosX='%f', PosY='%f', PosZ='%f', PosA='%f'", id, skin, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA]);
	mysql_tquery(BankSQLHandle, query);

	Iter_Add(Bankers, id);
	return 1;
}

CMD:setbankerpos(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/setbankerpos [banker id]");
	if(!Iter_Contains(Bankers, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid banker ID.");
	GetPlayerPos(playerid, BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ]);
	GetPlayerFacingAngle(playerid, BankerData[id][bankerA]);

	DestroyActor(BankerData[id][bankerActorID]);
	BankerData[id][bankerActorID] = CreateActor(BankerData[id][Skin], BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA]);
	if(IsValidActor(BankerData[id][bankerActorID])) SetActorInvulnerable(BankerData[id][bankerActorID], true);

	#if defined BANKER_USE_MAPICON
	Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, BankerData[id][bankerIconID], E_STREAMER_X, BankerData[id][bankerX]);
	Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, BankerData[id][bankerIconID], E_STREAMER_Y, BankerData[id][bankerY]);
	Streamer_SetFloatData(STREAMER_TYPE_MAP_ICON, BankerData[id][bankerIconID], E_STREAMER_Z, BankerData[id][bankerZ]);
	#endif

	Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, BankerData[id][bankerLabel], E_STREAMER_X, BankerData[id][bankerX]);
	Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, BankerData[id][bankerLabel], E_STREAMER_Y, BankerData[id][bankerY]);
	Streamer_SetFloatData(STREAMER_TYPE_3D_TEXT_LABEL, BankerData[id][bankerLabel], E_STREAMER_Z, BankerData[id][bankerZ]);

	SetPlayerPos(playerid, BankerData[id][bankerX] + (1.0 * floatsin(-BankerData[id][bankerA], degrees)), BankerData[id][bankerY] + (1.0 * floatcos(-BankerData[id][bankerA], degrees)), BankerData[id][bankerZ]);

	new query[144];
	mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bankers SET PosX='%f', PosY='%f', PosZ='%f', PosA='%f' WHERE ID=%d", BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA], id);
	mysql_tquery(BankSQLHandle, query);
	return 1;
}

CMD:setbankerskin(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id, skin;
	if(sscanf(params, "ii", id, skin)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/setbankerskin [banker id] [skin id]");
	if(!Iter_Contains(Bankers, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid banker ID.");
	if(!(0 <= skin <= 311)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid skin ID.");
	BankerData[id][Skin] = skin;

	if(IsValidActor(BankerData[id][bankerActorID])) DestroyActor(BankerData[id][bankerActorID]);
	BankerData[id][bankerActorID] = CreateActor(BankerData[id][Skin], BankerData[id][bankerX], BankerData[id][bankerY], BankerData[id][bankerZ], BankerData[id][bankerA]);
	if(IsValidActor(BankerData[id][bankerActorID])) SetActorInvulnerable(BankerData[id][bankerActorID], true);

	new query[48];
	mysql_format(BankSQLHandle, query, sizeof(query), "UPDATE bankers SET Skin=%d WHERE ID=%d", BankerData[id][Skin], id);
	mysql_tquery(BankSQLHandle, query);
	return 1;
}

CMD:removebanker(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/removebanker [banker id]");
	if(!Iter_Contains(Bankers, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid banker ID.");
	if(IsValidActor(BankerData[id][bankerActorID])) DestroyActor(BankerData[id][bankerActorID]);
	BankerData[id][bankerActorID] = -1;

	#if defined BANKER_USE_MAPICON
	if(IsValidDynamicMapIcon(BankerData[id][bankerIconID])) DestroyDynamicMapIcon(BankerData[id][bankerIconID]);
    BankerData[id][bankerIconID] = -1;
    #endif

    if(IsValidDynamic3DTextLabel(BankerData[id][bankerLabel])) DestroyDynamic3DTextLabel(BankerData[id][bankerLabel]);
    BankerData[id][bankerLabel] = Text3D: -1;

	Iter_Remove(Bankers, id);

	new query[48];
	mysql_format(BankSQLHandle, query, sizeof(query), "DELETE FROM bankers WHERE ID=%d", id);
	mysql_tquery(BankSQLHandle, query);
	return 1;
}

// Admin Commands for ATMs
CMD:createatm(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id = Iter_Free(ATMs);
	if(id == -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Can't create any more ATMs.");
	ATMData[id][atmRX] = ATMData[id][atmRY] = 0.0;

	GetPlayerPos(playerid, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ]);
	GetPlayerFacingAngle(playerid, ATMData[id][atmRZ]);

	ATMData[id][atmX] += (2.0 * floatsin(-ATMData[id][atmRZ], degrees));
    ATMData[id][atmY] += (2.0 * floatcos(-ATMData[id][atmRZ], degrees));
    ATMData[id][atmZ] -= 0.3;

	ATMData[id][atmObjID] = CreateDynamicObject(19324, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ], ATMData[id][atmRX], ATMData[id][atmRY], ATMData[id][atmRZ]);
    if(IsValidDynamicObject(ATMData[id][atmObjID]))
    {
        #if defined ROBBABLE_ATMS
        new dataArray[E_ATMDATA];
        format(dataArray[IDString], 8, "atm_sys");
        dataArray[refID] = id;
        Streamer_SetArrayData(STREAMER_TYPE_OBJECT, ATMData[id][atmObjID], E_STREAMER_EXTRA_ID, dataArray);
		#endif
		
        EditingATMID[playerid] = id;
        EditDynamicObject(playerid, ATMData[id][atmObjID]);
    }

	#if defined ATM_USE_MAPICON
	ATMData[id][atmIconID] = CreateDynamicMapIcon(ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ], 52, 0, .streamdistance = ATM_ICON_RANGE);
	#endif

	new label_string[64];
	format(label_string, sizeof(label_string), "ATM (%d)\n\n{FFFFFF}Use {F1C40F}/atm!", id);
	ATMData[id][atmLabel] = CreateDynamic3DTextLabel(label_string, 0x1ABC9CFF, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ] + 0.85, 5.0, .testlos = 1);

	new query[144];
	mysql_format(BankSQLHandle, query, sizeof(query), "INSERT INTO bank_atms SET ID=%d, PosX='%f', PosY='%f', PosZ='%f', RotX='%f', RotY='%f', RotZ='%f'", id, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ], ATMData[id][atmRX], ATMData[id][atmRY], ATMData[id][atmRZ]);
	mysql_tquery(BankSQLHandle, query);

	Iter_Add(ATMs, id);
	return 1;
}

CMD:editatm(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/editatm [ATM id]");
	if(!Iter_Contains(ATMs, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid ATM ID.");
	if(!IsPlayerInRangeOfPoint(playerid, 30.0, ATMData[id][atmX], ATMData[id][atmY], ATMData[id][atmZ])) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're not near the ATM you want to edit.");
	if(EditingATMID[playerid] != -1) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}You're already editing an ATM.");
	EditingATMID[playerid] = id;
	EditDynamicObject(playerid, ATMData[id][atmObjID]);
	return 1;
}

CMD:removeatm(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Only RCON admins can use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, 0xE88732FF, "SYNTAX: {FFFFFF}/removeatm [ATM id]");
	if(!Iter_Contains(ATMs, id)) return SendClientMessage(playerid, 0xE74C3CFF, "ERROR: {FFFFFF}Invalid ATM ID.");
	if(IsValidDynamicObject(ATMData[id][atmObjID])) DestroyDynamicObject(ATMData[id][atmObjID]);
	ATMData[id][atmObjID] = -1;

	#if defined ATM_USE_MAPICON
	if(IsValidDynamicMapIcon(ATMData[id][atmIconID])) DestroyDynamicMapIcon(ATMData[id][atmIconID]);
    ATMData[id][atmIconID] = -1;
    #endif

    if(IsValidDynamic3DTextLabel(ATMData[id][atmLabel])) DestroyDynamic3DTextLabel(ATMData[id][atmLabel]);
    ATMData[id][atmLabel] = Text3D: -1;

	#if defined ROBBABLE_ATMS
    if(ATMData[id][atmTimer] != -1) KillTimer(ATMData[id][atmTimer]);
    ATMData[id][atmTimer] = -1;

    if(IsValidDynamicPickup(ATMData[id][atmPickup])) DestroyDynamicPickup(ATMData[id][atmPickup]);
    ATMData[id][atmPickup] = -1;

    ATMData[id][atmHealth] = ATM_HEALTH;
	ATMData[id][atmRegen] = 0;
	#endif
	
	Iter_Remove(ATMs, id);
	
	new query[48];
	mysql_format(BankSQLHandle, query, sizeof(query), "DELETE FROM bank_atms WHERE ID=%d", id);
	mysql_tquery(BankSQLHandle, query);
	return 1;
}
